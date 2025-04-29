export const formatWeight = (weight) => {
  if (weight >= 100000) {
    return `${(weight / 1000).toFixed(1)} T`
  }
  return `${weight} kg`
} 