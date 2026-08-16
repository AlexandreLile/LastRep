<template>
  <Teleport to="body">
    <Transition name="record-fade">
      <div
        v-if="open"
        class="fixed inset-0 z-[100] flex items-center justify-center bg-black/70 backdrop-blur-sm"
        role="status"
        aria-live="polite"
        @click="close"
      >
        <div class="relative flex flex-col items-center px-8 py-10 text-center">
          <div class="record-confetti">
            <div
              v-for="n in 26"
              :key="n"
              class="record-confetti-piece"
              :style="pieceStyle(n)"
            ></div>
          </div>

          <div class="record-trophy mb-4">
            <Trophy class="h-16 w-16 drop-shadow-[0_0_12px_var(--record)]" style="color: var(--record)" />
          </div>

          <p class="record-pop text-sm font-bold tracking-[0.25em] uppercase" style="color: var(--record)">
            Nouveau record
          </p>

          <p class="record-pop-delay mt-2 text-4xl sm:text-5xl font-extrabold text-white">
            {{ mainText }}
          </p>

          <div
            v-if="deltaText"
            class="record-pop-delay-2 mt-4 inline-flex items-center gap-1 rounded-full px-4 py-1.5 text-lg font-bold"
            style="background: var(--record); color: var(--record-foreground)"
          >
            {{ deltaText }}
          </div>

          <p
            v-if="streakText"
            class="record-pop-delay-3 mt-3 text-sm font-semibold text-white/80"
          >
            {{ streakText }}
          </p>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { watch, onBeforeUnmount } from 'vue'
import { Trophy } from 'lucide-vue-next'

const props = defineProps({
  open: { type: Boolean, default: false },
  mainText: { type: String, default: '' },
  deltaText: { type: String, default: null },
  streakText: { type: String, default: null },
  autoCloseMs: { type: Number, default: 1800 }
})
const emit = defineEmits(['update:open'])

let closeTimer = null

const close = () => {
  emit('update:open', false)
}

// Répartit les confettis en cercle autour du trophée avec une distance/délai aléatoires
const pieceStyle = (n) => {
  const angle = (n / 26) * 360
  const distance = 90 + Math.random() * 70
  const x = Math.cos((angle * Math.PI) / 180) * distance
  const y = Math.sin((angle * Math.PI) / 180) * distance
  const palette = ['var(--primary)', 'var(--record)', '#ffffff']
  return {
    '--tx': `${x}px`,
    '--ty': `${y}px`,
    '--delay': `${Math.random() * 0.15}s`,
    background: palette[n % palette.length]
  }
}

watch(
  () => props.open,
  (isOpen) => {
    if (closeTimer) {
      clearTimeout(closeTimer)
      closeTimer = null
    }
    if (isOpen) {
      if (typeof navigator !== 'undefined' && navigator.vibrate) {
        navigator.vibrate([40, 30, 40, 30, 120])
      }
      closeTimer = setTimeout(close, props.autoCloseMs)
    }
  }
)

onBeforeUnmount(() => {
  if (closeTimer) clearTimeout(closeTimer)
})
</script>

<style scoped>
.record-fade-enter-active {
  transition: opacity 0.15s ease-out;
}
.record-fade-leave-active {
  transition: opacity 0.25s ease-in;
}
.record-fade-enter-from,
.record-fade-leave-to {
  opacity: 0;
}

.record-trophy {
  animation: record-trophy-pop 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) both;
}

.record-pop {
  animation: record-rise 0.35s ease-out 0.1s both;
}

.record-pop-delay {
  animation: record-rise 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) 0.2s both;
}

.record-pop-delay-2 {
  animation: record-rise 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) 0.35s both;
}

.record-pop-delay-3 {
  animation: record-rise 0.35s ease-out 0.5s both;
}

@keyframes record-trophy-pop {
  0% {
    transform: scale(0) rotate(-15deg);
    opacity: 0;
  }
  100% {
    transform: scale(1) rotate(0deg);
    opacity: 1;
  }
}

@keyframes record-rise {
  from {
    transform: translateY(12px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.record-confetti {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.record-confetti-piece {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 7px;
  height: 14px;
  opacity: 0;
  animation: record-confetti-burst 0.9s ease-out var(--delay, 0s) forwards;
}

@keyframes record-confetti-burst {
  0% {
    opacity: 1;
    transform: translate(-50%, -50%) rotate(0deg);
  }
  100% {
    opacity: 0;
    transform: translate(calc(-50% + var(--tx)), calc(-50% + var(--ty))) rotate(320deg);
  }
}

@media (prefers-reduced-motion: reduce) {
  .record-trophy,
  .record-pop,
  .record-pop-delay,
  .record-pop-delay-2,
  .record-pop-delay-3,
  .record-confetti-piece {
    animation: none;
    opacity: 1;
  }
}
</style>
