/**
 * Système de logging conditionnel
 * En production, les logs sont désactivés pour améliorer les performances
 */

// Utiliser import.meta.env pour Nuxt 3
const isDev = import.meta.env.DEV || import.meta.env.MODE === 'development'

export const logger = {
  log: (...args) => {
    if (isDev) {
      console.log(...args)
    }
  },
  
  error: (...args) => {
    // Les erreurs sont toujours loggées
    console.error(...args)
  },
  
  warn: (...args) => {
    if (isDev) {
      console.warn(...args)
    }
  },
  
  info: (...args) => {
    if (isDev) {
      console.info(...args)
    }
  },
  
  debug: (...args) => {
    if (isDev) {
      console.debug(...args)
    }
  }
}
