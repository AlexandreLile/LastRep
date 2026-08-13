<template>
  <div class="relative">
    <!-- Header -->
    <div class="mb-8 bg-card rounded-xl p-6">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 flex-shrink-0 bg-primary/10 rounded-full flex items-center justify-center">
          <Library class="h-6 w-6 text-primary" />
        </div>
        <div class="flex-1">
          <h2 class="text-2xl font-bold text-foreground">Catalogue de séances</h2>
          <p class="text-sm text-muted-foreground">Des séances prêtes à l'emploi à ajouter directement à vos séances</p>
        </div>
        <Button v-if="isAdmin" variant="outline" size="sm" as-child>
          <NuxtLink to="/admin/catalogue">
            <ShieldCheck class="mr-2 h-4 w-4" /> Gérer le catalogue
          </NuxtLink>
        </Button>
      </div>
    </div>

    <!-- Filtres par catégorie -->
    <Tabs v-if="categories.length > 1" default-value="Toutes" class="w-full mb-6" v-model="currentCategory">
      <div class="overflow-x-auto pb-2">
        <TabsList class="flex w-full min-w-max space-x-2">
          <TabsTrigger value="Toutes">Toutes</TabsTrigger>
          <TabsTrigger v-for="category in categories" :key="category" :value="category">
            {{ category }}
          </TabsTrigger>
        </TabsList>
      </div>
    </Tabs>

    <!-- Loading -->
    <div v-if="loading" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
    </div>

    <!-- Erreur -->
    <div v-else-if="error" class="text-red-500 text-center py-12">
      {{ error }}
    </div>

    <!-- Vide -->
    <div v-else-if="filteredTemplates.length === 0" class="text-center text-muted-foreground py-12">
      Aucune séance modèle disponible pour le moment.
    </div>

    <!-- Grille de séances modèles -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div
        v-for="template in filteredTemplates"
        :key="template.id"
        class="bg-card rounded-xl p-6 flex flex-col hover:shadow-md transition-all duration-300"
      >
        <div class="flex items-start gap-3 mb-3">
          <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center flex-shrink-0">
            <Dumbbell class="w-5 h-5 text-primary" />
          </div>
          <div class="flex-1">
            <div class="flex items-center gap-2 flex-wrap">
              <h3 class="text-lg font-semibold">{{ template.title }}</h3>
              <span class="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">{{ template.category }}</span>
            </div>
            <p v-if="template.description" class="text-sm text-muted-foreground mt-1">{{ template.description }}</p>
          </div>
        </div>

        <div class="flex-1 space-y-1.5 mb-4">
          <div
            v-for="templateExercise in template.exercises"
            :key="templateExercise.id"
            class="flex items-center justify-between text-sm bg-muted/50 px-3 py-1.5 rounded-lg"
          >
            <span class="text-foreground">{{ templateExercise.exercise.name }}</span>
            <span v-if="templateExercise.target_sets || templateExercise.target_reps" class="text-xs text-muted-foreground flex-shrink-0 ml-2">
              {{ templateExercise.target_sets ? `${templateExercise.target_sets}×` : '' }}{{ templateExercise.target_reps }}
            </span>
          </div>
        </div>

        <Button
          class="w-full sm:w-auto self-end bg-primary hover:bg-primary/90"
          :disabled="addingTemplateId === template.id"
          @click="handleAddTemplate(template)"
        >
          <span v-if="addingTemplateId === template.id" class="animate-spin mr-2">⌛</span>
          <PlusCircle v-else class="mr-2 h-4 w-4" />
          Ajouter à mes séances
        </Button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { toast } from 'vue-sonner';
import { Button } from '@/components/ui/button';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Dumbbell, PlusCircle, Library, ShieldCheck } from 'lucide-vue-next';
import { useSessionTemplates } from '~/composables/useSessionTemplates';
import { useAdmin } from '~/composables/useAdmin';

const router = useRouter();
const { templates, loading, error, getSessionTemplates, addTemplateToMySessions } = useSessionTemplates();
const { isAdmin, checkAdmin } = useAdmin();

const currentCategory = ref('Toutes');
const addingTemplateId = ref(null);

const categories = computed(() => {
  return [...new Set(templates.value.map(template => template.category))];
});

const filteredTemplates = computed(() => {
  if (currentCategory.value === 'Toutes') return templates.value;
  return templates.value.filter(template => template.category === currentCategory.value);
});

const handleAddTemplate = async (template) => {
  addingTemplateId.value = template.id;
  try {
    const result = await addTemplateToMySessions(template);
    if (result.success) {
      toast.success(`« ${template.title} » a été ajoutée à vos séances`);
      router.push(`/seances/${result.data.id}/edit`);
    } else {
      toast.error(result.error || "Erreur lors de l'ajout de la séance");
    }
  } finally {
    addingTemplateId.value = null;
  }
};

onMounted(() => {
  getSessionTemplates();
  checkAdmin();
});
</script>
