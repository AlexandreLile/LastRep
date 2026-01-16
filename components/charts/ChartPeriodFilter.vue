<template>
  <div class="flex items-center gap-2 mb-4">
    <span class="text-sm text-muted-foreground">Période :</span>
    <div class="flex gap-2">
      <button
        v-for="period in periods"
        :key="period.value"
        @click="$emit('update:modelValue', period.value)"
        :class="[
          'px-3 py-1.5 text-sm font-medium rounded-md transition-colors',
          modelValue === period.value
            ? 'bg-primary text-white'
            : 'bg-muted text-muted-foreground hover:bg-muted/80'
        ]"
      >
        {{ period.label }}
      </button>
    </div>
  </div>
</template>

<script setup>
defineProps({
  modelValue: {
    type: String,
    required: true
  }
})

defineEmits(['update:modelValue'])

const periods = [
  { value: 'day', label: 'Jour' },
  { value: 'week', label: 'Semaine' },
  { value: 'month', label: 'Mois' }
]
</script>
