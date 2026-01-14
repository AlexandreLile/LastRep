<template>
  <!-- Bouton de partage simple -->
  <Button 
    @click="openShareModal"
    variant="outline"
    class="flex items-center gap-2"
  >
    <Share2 class="h-4 w-4" />
    Partager
  </Button>

  <!-- Modal de partage -->
  <Dialog v-model:open="showShareModal">
    <DialogContent class="sm:max-w-md">
      <DialogHeader>
        <DialogTitle>Partager cette séance</DialogTitle>
        <DialogDescription>
          Partagez votre séance d'entraînement sur les réseaux sociaux
        </DialogDescription>
      </DialogHeader>

      <div class="space-y-4 py-4">
        <!-- Lien de partage -->
        <div class="space-y-2">
          <Label>Lien de partage</Label>
          <div class="flex gap-2">
            <Input 
              :value="shareUrl" 
              readonly 
              class="font-mono text-sm"
            />
            <Button 
              @click="copyLink"
              variant="outline"
              size="icon"
            >
              <Copy class="h-4 w-4" />
            </Button>
          </div>
          <p v-if="copied" class="text-sm text-green-600">
            ✓ Lien copié !
          </p>
        </div>

        <!-- Réseaux sociaux -->
        <div class="space-y-2">
          <Label>Partager sur</Label>
          <div class="grid grid-cols-3 gap-2">
            <Button 
              @click="shareOnTwitter"
              variant="outline"
              class="flex flex-col items-center gap-1 h-auto py-3"
            >
              <span class="text-2xl">🐦</span>
              <span class="text-xs">Twitter</span>
            </Button>
            
            <Button 
              @click="shareOnFacebook"
              variant="outline"
              class="flex flex-col items-center gap-1 h-auto py-3"
            >
              <span class="text-2xl">📘</span>
              <span class="text-xs">Facebook</span>
            </Button>
            
            <Button 
              @click="shareOnLinkedIn"
              variant="outline"
              class="flex flex-col items-center gap-1 h-auto py-3"
            >
              <span class="text-2xl">💼</span>
              <span class="text-xs">LinkedIn</span>
            </Button>
          </div>
        </div>

        <!-- Partage natif (mobile) -->
        <Button 
          v-if="canShareNative"
          @click="shareNative"
          class="w-full"
          variant="default"
        >
          <Share2 class="h-4 w-4 mr-2" />
          Partager (natif)
        </Button>
      </div>

      <DialogFooter>
        <Button 
          @click="showShareModal = false"
          variant="ghost"
        >
          Fermer
        </Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
</template>

<script setup>
import { ref, computed } from 'vue'
import { Share2, Copy } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { useToast } from '@/components/ui/toast'

const props = defineProps({
  sessionId: {
    type: String,
    required: true
  },
  sessionTitle: {
    type: String,
    default: 'Ma séance d\'entraînement'
  }
})

const showShareModal = ref(false)
const copied = ref(false)
const toast = useToast()

// URL de partage
const shareUrl = computed(() => {
  return `${window.location.origin}/share/session/${props.sessionId}`
})

// Vérifier si le navigateur supporte le partage natif
const canShareNative = computed(() => {
  return typeof navigator !== 'undefined' && 'share' in navigator
})

// Ouvrir la modal
const openShareModal = () => {
  showShareModal.value = true
}

// Copier le lien
const copyLink = async () => {
  try {
    await navigator.clipboard.writeText(shareUrl.value)
    copied.value = true
    toast.success('Lien copié dans le presse-papier !')
    
    setTimeout(() => {
      copied.value = false
    }, 2000)
  } catch (err) {
    toast.error('Impossible de copier le lien')
  }
}

// Partager sur Twitter
const shareOnTwitter = () => {
  const text = encodeURIComponent(`Regardez ma séance d'entraînement ! 💪\n\n${props.sessionTitle}`)
  const url = encodeURIComponent(shareUrl.value)
  window.open(`https://twitter.com/intent/tweet?text=${text}&url=${url}`, '_blank')
}

// Partager sur Facebook
const shareOnFacebook = () => {
  const url = encodeURIComponent(shareUrl.value)
  window.open(`https://www.facebook.com/sharer/sharer.php?u=${url}`, '_blank')
}

// Partager sur LinkedIn
const shareOnLinkedIn = () => {
  const url = encodeURIComponent(shareUrl.value)
  window.open(`https://www.linkedin.com/sharing/share-offsite/?url=${url}`, '_blank')
}

// Partage natif (mobile)
const shareNative = async () => {
  if (navigator.share) {
    try {
      await navigator.share({
        title: props.sessionTitle,
        text: 'Regardez ma séance d\'entraînement ! 💪',
        url: shareUrl.value
      })
    } catch (err) {
      // L'utilisateur a annulé ou erreur
      if (err.name !== 'AbortError') {
        toast.error('Erreur lors du partage')
      }
    }
  }
}
</script>
