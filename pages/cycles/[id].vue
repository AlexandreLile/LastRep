<template>
  <!-- Route enfant active (ex: /cycles/:id/seances/:sessionId) -->
  <NuxtPage v-if="hasChildRoute" />

  <div v-else class="relative space-y-6">
    <!-- Chargement -->
    <div v-if="loading" class="flex justify-center items-center h-64">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
    </div>

    <!-- Erreur -->
    <div v-else-if="error" class="text-red-500 text-center py-8 bg-card rounded-xl p-6">
      <AlertTriangle class="h-12 w-12 mx-auto mb-4" />
      {{ error }}
    </div>

    <template v-else-if="cycle">
      <!-- Header -->
      <div class="bg-card rounded-xl p-6">
        <div class="flex items-start justify-between gap-3 mb-4">
          <div>
            <button
              class="flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground mb-2 transition-colors"
              @click="navigateTo('/cycles')"
            >
              <ChevronLeft class="h-4 w-4" /> Cycles
            </button>
            <div class="flex items-center gap-2">
              <h2 class="text-2xl font-bold">{{ cycle.name }}</h2>
              <button @click="openEditDialog" class="text-muted-foreground hover:text-foreground transition-colors flex-shrink-0">
                <Pencil class="h-4 w-4" />
              </button>
            </div>
            <p class="text-sm text-muted-foreground mt-1">
              {{ formatDate(cycle.started_at) }}
              <span v-if="cycle.ended_at"> → {{ formatDate(cycle.ended_at) }}</span>
            </p>
          </div>
          <span
            class="text-xs px-2.5 py-1 rounded-full font-medium flex-shrink-0"
            :class="cycle.ended_at ? 'bg-muted text-muted-foreground' : 'bg-primary/15 text-primary'"
          >
            {{ cycle.ended_at ? 'Terminé' : 'En cours' }}
          </span>
        </div>

        <div v-if="!cycle.ended_at">
          <Button variant="outline" size="sm" @click="showEndDialog = true" class="flex items-center gap-1.5">
            <CheckCircle2 class="h-4 w-4" />
            Clôturer le cycle
          </Button>
        </div>
      </div>

      <!-- Stats du cycle -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="bg-card rounded-xl p-6 border border-border">
          <div class="flex flex-col h-full">
            <div class="mb-3 flex items-center gap-3">
              <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                <Dumbbell class="w-5 h-5 text-primary" />
              </div>
              <h3 class="text-sm font-medium text-muted-foreground">Séances complétées</h3>
            </div>
            <p class="text-3xl font-bold text-foreground mt-auto">{{ cycleSessionCount }}</p>
            <p class="text-sm text-muted-foreground mt-1">séances réalisées</p>
          </div>
        </div>

        <div class="bg-card rounded-xl p-6 border border-border">
          <div class="flex flex-col h-full">
            <div class="mb-3 flex items-center gap-3">
              <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                <Weight class="w-5 h-5 text-primary" />
              </div>
              <h3 class="text-sm font-medium text-muted-foreground">Poids total soulevé</h3>
            </div>
            <div v-if="loadingWeight" class="mt-auto flex items-center py-1">
              <div class="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-primary"></div>
            </div>
            <template v-else>
              <p class="text-3xl font-bold text-foreground mt-auto">{{ formatWeight(cycleWeight) }}</p>
              <div class="flex flex-wrap items-center justify-between gap-2 mt-1">
                <p class="text-sm text-muted-foreground">poids total soulevé</p>
                <div v-if="cycleSessionCount > 0" class="bg-primary/10 text-primary text-xs font-medium px-3 py-1.5 rounded-full border border-primary/20 shadow-sm">
                  {{ formatWeight(Math.round(cycleWeight / cycleSessionCount)) }}/séance
                </div>
              </div>
            </template>
          </div>
        </div>

        <div class="bg-card rounded-xl p-6 border border-border">
          <div class="flex flex-col h-full">
            <div class="mb-3 flex items-center gap-3">
              <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                <Clock class="w-5 h-5 text-primary" />
              </div>
              <h3 class="text-sm font-medium text-muted-foreground">Temps d'entraînement</h3>
            </div>
            <p class="text-3xl font-bold text-foreground mt-auto">{{ formatTotalDuration(cycleTotalMinutes) }}</p>
            <div class="flex flex-wrap items-center justify-between gap-2 mt-1">
              <p class="text-sm text-muted-foreground">temps total</p>
              <div v-if="cycleSessionCount > 0" class="bg-primary/10 text-primary text-xs font-medium px-3 py-1.5 rounded-full border border-primary/20 shadow-sm">
                {{ formatTotalDuration(Math.round(cycleTotalMinutes / cycleSessionCount)) }}/séance
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Mensurations -->
      <div v-if="cycle.measurement_start || cycle.measurement_end" class="bg-card rounded-xl overflow-hidden">
        <button
          class="w-full flex items-center justify-between gap-3 p-6 hover:bg-muted/30 transition-colors"
          @click="showMeasurements = !showMeasurements"
        >
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center flex-shrink-0">
              <Ruler class="w-5 h-5 text-primary" />
            </div>
            <h3 class="text-lg font-semibold">Mensurations</h3>
          </div>
          <ChevronDown class="h-4 w-4 text-muted-foreground transition-transform flex-shrink-0" :class="{ 'rotate-180': showMeasurements }" />
        </button>
        <div v-if="showMeasurements" class="px-6 pb-6 border-t border-border/50">
          <div class="overflow-x-auto pt-4">
            <table class="w-full text-sm">
              <thead>
                <tr class="text-left text-muted-foreground border-b">
                  <th class="pb-2 font-medium">Mesure</th>
                  <th class="pb-2 font-medium text-right" v-if="cycle.measurement_start">Début</th>
                  <th class="pb-2 font-medium text-right" v-if="cycle.measurement_end">Fin</th>
                  <th class="pb-2 font-medium text-right" v-if="measurementDiff">Évolution</th>
                </tr>
              </thead>
              <tbody class="divide-y">
                <tr v-for="row in measurementRows" :key="row.key" class="py-2">
                  <td class="py-2 text-muted-foreground">{{ row.label }}</td>
                  <td class="py-2 text-right" v-if="cycle.measurement_start">
                    {{ formatMeasure(cycle.measurement_start[row.key], row.unit) }}
                  </td>
                  <td class="py-2 text-right" v-if="cycle.measurement_end">
                    {{ formatMeasure(cycle.measurement_end[row.key], row.unit) }}
                  </td>
                  <td class="py-2 text-right" v-if="measurementDiff">
                    <span
                      v-if="measurementDiff[row.key]"
                      :class="diffClass(measurementDiff[row.key].diff, row.key)"
                      class="font-medium"
                    >
                      {{ measurementDiff[row.key].diff > 0 ? '+' : '' }}{{ measurementDiff[row.key].diff.toFixed(1) }} {{ row.unit }}
                      <span class="text-xs opacity-70">({{ measurementDiff[row.key].diff_pct?.toFixed(1) }}%)</span>
                    </span>
                    <span v-else class="text-muted-foreground">—</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-if="!cycle.measurement_end && !cycle.ended_at" class="mt-3">
            <button class="text-sm text-primary hover:underline" @click="showEndDialog = true">
              + Ajouter des mensurations de fin
            </button>
          </div>
        </div>
      </div>

      <!-- Ajouter mensurations si aucune -->
      <div v-else class="bg-card rounded-xl p-5">
        <button
          class="flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors"
          @click="showStartMeasurementsDialog = true"
        >
          <Ruler class="h-4 w-4" />
          Ajouter des mensurations de départ
        </button>
      </div>

      <!-- Séances du cycle -->
      <div class="space-y-4">
        <div class="flex items-center justify-between px-1">
          <h3 class="text-lg font-semibold">Séances du cycle</h3>
          <Button size="sm" @click="openAddSlot" class="flex items-center gap-1.5">
            <Plus class="h-4 w-4" /> Ajouter une séance
          </Button>
        </div>

        <div v-if="!cycle.slots?.length" class="flex flex-col items-center justify-center py-10 bg-card rounded-xl text-muted-foreground">
          <LayoutGrid class="w-10 h-10 mb-2 opacity-30" />
          <p class="text-sm">Aucune séance — ajoutez-en une pour commencer</p>
        </div>

        <div v-for="slot in cycle.slots" :key="slot.id" class="bg-card rounded-xl p-5">
          <!-- Titre -->
          <div class="min-w-0 mb-3">
            <h4 class="font-semibold truncate">{{ slot.workout_session?.title || slot.name }}</h4>
            <p v-if="slot.name !== slot.workout_session?.title && slot.workout_session" class="text-xs text-muted-foreground mt-0.5 truncate">
              {{ slot.name }}
            </p>
          </div>

          <!-- Actions : progression + démarrer -->
          <div class="flex items-center gap-2 flex-wrap mb-3">
            <span class="text-xs text-muted-foreground mr-auto">
              {{ slot.performed_sessions?.length || 0 }} passage{{ slot.performed_sessions?.length !== 1 ? 's' : '' }}
            </span>
            <Button
              v-if="slot.performed_sessions?.length"
              size="sm"
              variant="outline"
              @click="navigateTo(`/cycles/${cycleId}/slots/${slot.id}`)"
              class="flex items-center gap-1.5"
            >
              <BarChart2 class="h-3.5 w-3.5" />
              Progression
            </Button>
            <Button size="sm" @click="startSlot(slot)" class="flex items-center gap-1.5">
              <Play class="h-3.5 w-3.5" />
              Démarrer
            </Button>
          </div>

          <!-- Sessions réalisées dans ce cycle pour ce créneau -->
          <div v-if="slot.performed_sessions?.length" class="space-y-1.5">
            <template v-for="(session, idx) in [...(slot.performed_sessions)].sort((a, b) => new Date(b.started_at) - new Date(a.started_at))" :key="session.id">
              <div
                v-if="idx < 4 || expandedSlots.has(slot.id)"
                class="flex items-center justify-between py-2 px-3 bg-muted/40 rounded-lg cursor-pointer hover:bg-muted/70 transition-colors"
                @click="navigateTo(`/cycles/${cycle.id}/seances/${session.id}`)"
              >
                <div class="flex items-center gap-2">
                  <span class="text-xs font-medium text-muted-foreground w-5 text-center">#{{ slot.performed_sessions.length - idx }}</span>
                  <span class="text-sm">{{ formatDate(session.started_at) }}</span>
                </div>
                <div class="flex items-center gap-2">
                  <span v-if="session.ended_at" class="text-xs text-muted-foreground">
                    {{ duration(session.started_at, session.ended_at) }}
                  </span>
                  <ChevronRight class="h-4 w-4 text-muted-foreground" />
                </div>
              </div>
            </template>
            <button
              v-if="slot.performed_sessions.length > 4"
              class="w-full flex items-center justify-center gap-1.5 text-xs text-muted-foreground hover:text-foreground py-1.5 transition-colors"
              @click="toggleSlotExpand(slot.id)"
            >
              <ChevronDown
                class="h-3.5 w-3.5 transition-transform"
                :class="{ 'rotate-180': expandedSlots.has(slot.id) }"
              />
              {{ expandedSlots.has(slot.id) ? 'Réduire' : `Voir ${slot.performed_sessions.length - 4} de plus` }}
            </button>
          </div>
          <div v-else class="text-xs text-muted-foreground py-1">
            Pas encore réalisée dans ce cycle
          </div>

          <!-- Retirer du cycle -->
          <div class="mt-4 pt-3 border-t border-border/50 flex justify-end">
            <button
              class="flex items-center gap-1.5 text-xs text-muted-foreground hover:text-destructive transition-colors"
              @click="confirmDeleteSlot(slot)"
            >
              <X class="h-3.5 w-3.5" />
              Retirer du cycle
            </button>
          </div>
        </div>
      </div>
    </template>

    <!-- ── Dialog : Ajouter une séance au cycle ────────────────────────── -->
    <Dialog :open="showAddSlot" @update:open="val => { if (!val) closeAddSlot() }">
      <DialogContent class="max-w-md max-h-[85vh] flex flex-col p-0">
        <DialogHeader class="p-6 pb-0">
          <DialogTitle>Ajouter une séance au cycle</DialogTitle>
          <DialogDescription>Choisissez une séance existante ou créez-en une nouvelle.</DialogDescription>
        </DialogHeader>

        <!-- Onglets -->
        <div class="flex border-b mx-6 mt-4">
          <button
            class="flex-1 pb-2 text-sm font-medium border-b-2 transition-colors"
            :class="addMode === 'existing' ? 'border-primary text-primary' : 'border-transparent text-muted-foreground hover:text-foreground'"
            @click="addMode = 'existing'"
          >
            Séance existante
          </button>
          <button
            class="flex-1 pb-2 text-sm font-medium border-b-2 transition-colors"
            :class="addMode === 'new' ? 'border-primary text-primary' : 'border-transparent text-muted-foreground hover:text-foreground'"
            @click="addMode = 'new'"
          >
            Nouvelle séance
          </button>
        </div>

        <!-- Contenu scrollable -->
        <div class="flex-1 min-h-0 overflow-y-auto p-6 pt-4">

          <!-- Mode : séance existante -->
          <div v-if="addMode === 'existing'" class="space-y-3">
            <div class="relative">
              <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
              <Input v-model="sessionSearch" placeholder="Rechercher une séance…" class="pl-10" />
            </div>

            <div v-if="loadingSessions" class="flex justify-center py-6">
              <div class="animate-spin rounded-full h-6 w-6 border-t-2 border-b-2 border-primary"></div>
            </div>

            <div v-else-if="filteredSessions.length === 0" class="text-sm text-muted-foreground text-center py-6">
              Aucune séance trouvée
            </div>

            <button
              v-for="s in filteredSessions"
              :key="s.id"
              class="w-full flex items-center gap-3 p-3 rounded-xl border transition-all text-left"
              :class="selectedSessionId === s.id
                ? 'border-primary bg-primary/5'
                : 'border-transparent bg-muted/40 hover:bg-muted/70'"
              @click="selectedSessionId = s.id"
            >
              <div
                class="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0"
                :class="selectedSessionId === s.id ? 'bg-primary/20' : 'bg-muted'"
              >
                <Check v-if="selectedSessionId === s.id" class="h-4 w-4 text-primary" />
                <Dumbbell v-else class="h-4 w-4 text-muted-foreground" />
              </div>
              <div class="min-w-0">
                <p class="font-medium text-sm truncate">{{ s.title }}</p>
                <p class="text-xs text-muted-foreground">{{ s.exercises?.length || 0 }} exercice{{ s.exercises?.length !== 1 ? 's' : '' }}</p>
              </div>
            </button>

            <p class="text-xs text-muted-foreground pt-1 pb-1 bg-muted/30 rounded-lg px-3 py-2">
              Les séances déjà réalisées hors cycle ne sont pas comptées — seules les prochaines séances faites depuis ce cycle apparaîtront dans les stats.
            </p>
          </div>

          <!-- Mode : nouvelle séance -->
          <div v-else class="space-y-4">
            <div class="space-y-1.5">
              <label class="text-sm font-medium">Nom de la séance</label>
              <Input v-model="newSessionTitle" placeholder="ex: Push, Jambes, Full Body A…" />
            </div>
            <p class="text-xs text-muted-foreground bg-muted/30 rounded-lg px-3 py-2">
              Une séance vide sera créée et ajoutée au cycle. Vous pourrez y ajouter des exercices juste après.
            </p>
          </div>
        </div>

        <div class="p-6 pt-0 flex gap-2 justify-end border-t">
          <Button variant="outline" @click="closeAddSlot">Annuler</Button>
          <Button
            @click="handleAddSlot"
            :disabled="(addMode === 'existing' && !selectedSessionId) || (addMode === 'new' && !newSessionTitle.trim()) || addingSlot"
          >
            <span v-if="addingSlot" class="flex items-center gap-2">
              <div class="animate-spin rounded-full h-3 w-3 border-t-2 border-white"></div>
              Ajout…
            </span>
            <span v-else>{{ addMode === 'new' ? 'Créer et ajouter' : 'Ajouter au cycle' }}</span>
          </Button>
        </div>
      </DialogContent>
    </Dialog>

    <!-- ── Dialog : Clôturer ───────────────────────────────────────────── -->
    <Dialog :open="showEndDialog" @update:open="showEndDialog = $event">
      <DialogContent class="max-w-md">
        <DialogHeader>
          <DialogTitle>Clôturer le cycle</DialogTitle>
          <DialogDescription>Définissez la date de fin et ajoutez vos mensurations finales si souhaité.</DialogDescription>
        </DialogHeader>
        <div class="space-y-4 py-2">
          <div class="space-y-1.5">
            <label class="text-sm font-medium">Date de fin</label>
            <Input v-model="endForm.ended_at" type="date" />
          </div>
          <div class="border rounded-xl overflow-hidden">
            <button
              type="button"
              class="w-full flex items-center justify-between p-4 text-sm font-medium hover:bg-muted/30 transition-colors"
              @click="showEndMeasurements = !showEndMeasurements"
            >
              <span class="flex items-center gap-2">
                <Ruler class="h-4 w-4 text-muted-foreground" />
                Mensurations de fin
                <span class="text-xs text-muted-foreground font-normal">(optionnel)</span>
              </span>
              <ChevronDown class="h-4 w-4 text-muted-foreground transition-transform" :class="{ 'rotate-180': showEndMeasurements }" />
            </button>
            <div v-if="showEndMeasurements" class="p-4 pt-0 space-y-3 border-t">
              <div class="grid grid-cols-2 gap-3">
                <div class="space-y-1" v-for="f in measurementRows" :key="f.key">
                  <label class="text-xs text-muted-foreground">{{ f.label }} ({{ f.unit }})</label>
                  <Input v-model.number="endForm.measurements[f.key]" type="number" step="0.1" :placeholder="f.placeholder" />
                </div>
              </div>
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="showEndDialog = false">Annuler</Button>
          <Button @click="handleEndCycle" :disabled="!endForm.ended_at || ending">
            {{ ending ? 'Enregistrement…' : 'Clôturer' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- ── Dialog : Mensurations de départ ──────────────────────────── -->
    <Dialog :open="showStartMeasurementsDialog" @update:open="showStartMeasurementsDialog = $event">
      <DialogContent class="max-w-md">
        <DialogHeader>
          <DialogTitle>Mensurations de départ</DialogTitle>
          <DialogDescription>Enregistrez vos mensurations au début de ce cycle.</DialogDescription>
        </DialogHeader>
        <div class="space-y-3 py-2">
          <div class="grid grid-cols-2 gap-3">
            <div class="space-y-1" v-for="f in measurementRows" :key="f.key">
              <label class="text-xs text-muted-foreground">{{ f.label }} ({{ f.unit }})</label>
              <Input v-model.number="startForm.measurements[f.key]" type="number" step="0.1" :placeholder="f.placeholder" />
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="showStartMeasurementsDialog = false">Annuler</Button>
          <Button @click="handleSaveStartMeasurements" :disabled="savingStart">
            {{ savingStart ? 'Enregistrement…' : 'Enregistrer' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- ── Dialog : Modifier cycle ─────────────────────────────────────── -->
    <Dialog :open="showEditDialog" @update:open="showEditDialog = $event">
      <DialogContent class="max-w-sm">
        <DialogHeader>
          <DialogTitle>Modifier le cycle</DialogTitle>
        </DialogHeader>
        <div class="py-2">
          <Input v-model="editForm.name" placeholder="Nom du cycle" @keyup.enter="handleEditCycle" />
        </div>
        <DialogFooter class="flex-col gap-2 sm:flex-row sm:justify-between sm:items-center">
          <Button
            variant="ghost"
            class="text-destructive hover:text-destructive hover:bg-destructive/10 justify-start"
            @click="showEditDialog = false; showDeleteDialog = true"
          >
            <Trash2 class="h-4 w-4 mr-1.5" />
            Supprimer le cycle
          </Button>
          <div class="flex gap-2 justify-end">
            <Button variant="outline" @click="showEditDialog = false">Annuler</Button>
            <Button @click="handleEditCycle" :disabled="!editForm.name.trim() || saving">
              {{ saving ? 'Enregistrement…' : 'Enregistrer' }}
            </Button>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- ── Dialog : Supprimer cycle ───────────────────────────────────── -->
    <AlertDialog :open="showDeleteDialog" @update:open="showDeleteDialog = $event">
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Supprimer le cycle</AlertDialogTitle>
          <AlertDialogDescription>
            Cette action est irréversible. Le cycle et ses séances seront supprimés du cycle, mais les séances restent dans votre bibliothèque.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Annuler</AlertDialogCancel>
          <AlertDialogAction class="bg-destructive text-destructive-foreground hover:bg-destructive/90" @click="handleDelete">
            Supprimer
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>

    <!-- ── Dialog : Supprimer créneau ─────────────────────────────────── -->
    <AlertDialog :open="!!slotToDelete" @update:open="val => { if (!val) slotToDelete = null }">
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Retirer cette séance du cycle ?</AlertDialogTitle>
          <AlertDialogDescription>
            La séance reste dans votre bibliothèque. Seul son rattachement à ce cycle est supprimé.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel @click="slotToDelete = null">Annuler</AlertDialogCancel>
          <AlertDialogAction class="bg-destructive text-destructive-foreground hover:bg-destructive/90" @click="handleDeleteSlot">
            Retirer
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  </div>
</template>


<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import {
  AlertTriangle, ChevronLeft, ChevronRight, ChevronDown, Plus, Play,
  Pencil, CheckCircle2, Ruler, LayoutGrid, Search, Dumbbell, Check, X,
  Weight, Clock, BarChart2, Trash2
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter
} from '@/components/ui/dialog'
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle
} from '@/components/ui/alert-dialog'
import { useCycle } from '~/composables/useCycle'
import { useCycleStats } from '~/composables/useCycleStats'
import { usePerformedSession } from '~/composables/usePerformedSession'
import { getOfflineUser } from '~/utils/offlineTraining'

const route = useRoute()
const cycleId = route.params.id
const hasChildRoute = computed(() =>
  !!route.params.sessionId || !!route.params.slotId || route.path.endsWith('/recap')
)

const { loading, error, fetchCycle, updateCycle, deleteCycle, createSlot, deleteSlot, saveMeasurement } = useCycle()
const { computeMeasurementDiff } = useCycleStats()

const cycle = ref(null)
const cycleWeight = ref(0)
const loadingWeight = ref(false)

// Stats calculées depuis les données déjà chargées
const cycleSessionCount = computed(() =>
  (cycle.value?.slots || []).reduce((sum, s) => sum + (s.performed_sessions?.length || 0), 0)
)

const cycleTotalMinutes = computed(() =>
  (cycle.value?.slots || []).flatMap(s => s.performed_sessions || []).reduce((sum, s) => {
    if (!s.started_at || !s.ended_at) return sum
    return sum + Math.round((new Date(s.ended_at) - new Date(s.started_at)) / 60000)
  }, 0)
)

// Dialog states
const showDeleteDialog = ref(false)
const showEndDialog = ref(false)
const showStartMeasurementsDialog = ref(false)
const showMeasurements = ref(false)
const showEndMeasurements = ref(false)
const ending = ref(false)
const slotToDelete = ref(null)

// Add slot dialog
const showAddSlot = ref(false)
const addMode = ref('existing') // 'existing' | 'new'
const addingSlot = ref(false)
const sessionSearch = ref('')
const selectedSessionId = ref(null)
const newSessionTitle = ref('')
const allSessions = ref([])
const loadingSessions = ref(false)

const endForm = reactive({ ended_at: new Date().toISOString().split('T')[0], measurements: {} })
const startForm = reactive({ measurements: {} })
const savingStart = ref(false)
const expandedSlots = ref(new Set())
const toggleSlotExpand = (slotId) => {
  const next = new Set(expandedSlots.value)
  next.has(slotId) ? next.delete(slotId) : next.add(slotId)
  expandedSlots.value = next
}

// Edit dialog
const showEditDialog = ref(false)
const editForm = reactive({ name: '' })
const saving = ref(false)

const openEditDialog = () => {
  editForm.name = cycle.value?.name || ''
  showEditDialog.value = true
}

const handleEditCycle = async () => {
  if (!editForm.name.trim()) return
  saving.value = true
  await updateCycle(cycleId, { name: editForm.name.trim() })
  if (cycle.value) cycle.value.name = editForm.name.trim()
  saving.value = false
  showEditDialog.value = false
}

const measurementRows = [
  { key: 'weight_kg', label: 'Poids', unit: 'kg', placeholder: '75' },
  { key: 'arm_cm', label: 'Tour de bras', unit: 'cm', placeholder: '36' },
  { key: 'waist_cm', label: 'Tour de taille', unit: 'cm', placeholder: '80' },
  { key: 'chest_cm', label: 'Tour de poitrine', unit: 'cm', placeholder: '100' },
  { key: 'thigh_cm', label: 'Tour de cuisse', unit: 'cm', placeholder: '58' },
  { key: 'calf_cm', label: 'Tour de mollet', unit: 'cm', placeholder: '38' }
]

const measurementDiff = computed(() =>
  computeMeasurementDiff(cycle.value?.measurement_start, cycle.value?.measurement_end)
)

const filteredSessions = computed(() => {
  const q = sessionSearch.value.toLowerCase().trim()
  return allSessions.value.filter(s =>
    !q || s.title?.toLowerCase().includes(q)
  )
})

// ── Chargement ──────────────────────────────────────────────────────────────

const load = async () => {
  const { data } = await fetchCycle(cycleId)
  if (data) cycle.value = data
  await loadCycleWeight()
}

const loadCycleWeight = async () => {
  const sessionIds = (cycle.value?.slots || [])
    .flatMap(s => s.performed_sessions || [])
    .map(s => s.id)

  if (!sessionIds.length) { cycleWeight.value = 0; return }

  loadingWeight.value = true
  const supabase = useSupabaseClient()
  const { data } = await supabase
    .from('exerciseset')
    .select('weight_kg, reps')
    .in('performed_session_id', sessionIds)

  cycleWeight.value = (data || []).reduce((sum, s) => {
    if (s.weight_kg == null || !s.reps) return sum
    return sum + s.weight_kg * s.reps
  }, 0)
  loadingWeight.value = false
}

const loadSessions = async () => {
  loadingSessions.value = true
  const supabase = useSupabaseClient()
  const { data } = await supabase
    .from('workoutsession')
    .select('id, title, exercises:workoutexercise(id)')
    .order('date', { ascending: false })
  allSessions.value = data || []
  loadingSessions.value = false
}

// ── Dialog ajouter créneau ──────────────────────────────────────────────────

const openAddSlot = () => {
  addMode.value = 'existing'
  selectedSessionId.value = null
  newSessionTitle.value = ''
  sessionSearch.value = ''
  showAddSlot.value = true
  loadSessions()
}

const closeAddSlot = () => {
  showAddSlot.value = false
}

const handleAddSlot = async () => {
  addingSlot.value = true
  const slotOrder = cycle.value?.slots?.length || 0
  const supabase = useSupabaseClient()

  if (addMode.value === 'existing' && selectedSessionId.value) {
    const session = allSessions.value.find(s => s.id === selectedSessionId.value)
    await createSlot(cycleId, {
      name: session?.title || 'Séance',
      slot_order: slotOrder,
      workout_session_id: selectedSessionId.value
    })
    closeAddSlot()
    await load()

  } else if (addMode.value === 'new' && newSessionTitle.value.trim()) {
    const user = (await supabase.auth.getUser()).data.user
    // Créer la séance
    const { data: newSession, error: sessionErr } = await supabase
      .from('workoutsession')
      .insert({ title: newSessionTitle.value.trim(), user_id: user.id, date: new Date().toISOString() })
      .select()
      .single()

    if (!sessionErr && newSession) {
      await createSlot(cycleId, {
        name: newSession.title,
        slot_order: slotOrder,
        workout_session_id: newSession.id
      })
      closeAddSlot()
      await load()
      // Naviguer vers l'édition pour ajouter des exercices
      navigateTo(`/seances/${newSession.id}/edit?cycle=${cycleId}`)
    }
  }

  addingSlot.value = false
}

// ── Supprimer créneau ───────────────────────────────────────────────────────

const confirmDeleteSlot = (slot) => { slotToDelete.value = slot }

const handleDeleteSlot = async () => {
  if (!slotToDelete.value) return
  await deleteSlot(slotToDelete.value.id)
  slotToDelete.value = null
  await load()
}

// ── Mensurations de départ ──────────────────────────────────────────────────

const handleSaveStartMeasurements = async () => {
  savingStart.value = true
  await saveMeasurement(cycleId, 'start', startForm.measurements, cycle.value?.started_at)
  await load()
  showStartMeasurementsDialog.value = false
  Object.keys(startForm.measurements).forEach(k => delete startForm.measurements[k])
  savingStart.value = false
}

// ── Clôturer ────────────────────────────────────────────────────────────────

const handleEndCycle = async () => {
  ending.value = true
  await updateCycle(cycleId, { ended_at: endForm.ended_at })
  const hasData = Object.values(endForm.measurements).some(v => v != null && v !== '')
  if (hasData) await saveMeasurement(cycleId, 'end', endForm.measurements, endForm.ended_at)
  showEndDialog.value = false
  ending.value = false
  navigateTo(`/cycles/${cycleId}/recap`)
}

// ── Supprimer cycle ─────────────────────────────────────────────────────────

const handleDelete = async () => {
  await deleteCycle(cycleId)
  navigateTo('/cycles')
}

// ── Démarrer une séance depuis le cycle ─────────────────────────────────────

const startSlot = async (slot) => {
  const supabase = useSupabaseClient()
  const { prepareSession } = usePerformedSession(supabase)
  const user = await getOfflineUser(supabase)
  if (!user) return
  prepareSession(slot.workout_session_id, user.id, slot.id)
  navigateTo(`/seances/${slot.workout_session_id}/start?slot=${slot.id}&cycle=${cycleId}`)
}

// ── Utilitaires ─────────────────────────────────────────────────────────────

const formatDate = (d) => {
  if (!d) return ''
  return new Date(d).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' })
}

const formatMeasure = (val, unit) => {
  if (val == null) return '—'
  return `${parseFloat(val).toFixed(unit === 'kg' ? 1 : 0)} ${unit}`
}

const diffClass = (diff, key) => {
  if (key === 'waist_cm') return diff < 0 ? 'text-green-500' : diff > 0 ? 'text-red-500' : 'text-muted-foreground'
  return diff > 0 ? 'text-green-500' : diff < 0 ? 'text-red-500' : 'text-muted-foreground'
}

const duration = (start, end) => {
  const mins = Math.round((new Date(end) - new Date(start)) / 60000)
  if (mins < 60) return `${mins} min`
  return `${Math.floor(mins / 60)}h${mins % 60 > 0 ? String(mins % 60).padStart(2, '0') : ''}`
}

const formatTotalDuration = (minutes) => {
  if (!minutes) return '0min'
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  if (h > 0) return `${h}h${m > 0 ? `${m}m` : ''}`
  return `${minutes}min`
}

const formatWeight = (w) => {
  if (!w) return '0kg'
  if (w >= 1000000) return `${(w / 1000000).toFixed(1)}T`
  if (w >= 1000) return `${(w / 1000).toFixed(1)}K`
  return `${Math.round(w)}kg`
}

onMounted(load)
</script>
