# 📧 Templates d'email Supabase

Ce dossier contient les templates d'email personnalisés pour Supabase Auth.

## 📋 Template disponible

### `confirmation.html`
Template professionnel pour la confirmation d'email lors de l'inscription.

**Caractéristiques :**
- ✅ Design moderne et responsive
- ✅ Compatible avec tous les clients email (Gmail, Outlook, Apple Mail, etc.)
- ✅ Couleurs de la marque LastRep (#FE751C)
- ✅ Bouton CTA clair et visible
- ✅ Lien alternatif si le bouton ne fonctionne pas
- ✅ Informations de sécurité
- ✅ Footer avec liens légaux

## 🚀 Configuration

Le template est déjà configuré dans `supabase/config.toml` :

```toml
[auth.email.template.confirmation]
subject = "Confirmez votre email - LastRep"
content_path = "./supabase/templates/confirmation.html"
```

## 📝 Variables disponibles

Le template utilise les variables suivantes fournies par Supabase :

- `{{ .ConfirmationURL }}` - Lien de confirmation de l'email
- `{{ .SiteURL }}` - URL de votre site
- `{{ .Year }}` - Année actuelle (si disponible)

## 🔧 Utilisation en production

Pour utiliser ce template en production sur Supabase :

1. **Via le Dashboard Supabase** (recommandé) :
   - Allez sur [app.supabase.com](https://app.supabase.com)
   - Sélectionnez votre projet
   - Menu **Authentication** → **Email Templates**
   - Sélectionnez **"Confirmation"**
   - Copiez le contenu de `confirmation.html`
   - Collez-le dans l'éditeur
   - Modifiez le sujet si nécessaire
   - Sauvegardez

2. **Via config.toml** (pour développement local) :
   - Le fichier `config.toml` est déjà configuré
   - Le template sera utilisé automatiquement en local

## 🎨 Personnalisation

Pour personnaliser le template :

1. Modifiez `confirmation.html`
2. Ajustez les couleurs dans les styles inline
3. Modifiez les textes selon vos besoins
4. Testez avec différents clients email

## 📱 Compatibilité

Le template est testé et compatible avec :
- ✅ Gmail (Web, iOS, Android)
- ✅ Outlook (Web, Desktop, Mobile)
- ✅ Apple Mail (macOS, iOS)
- ✅ Yahoo Mail
- ✅ Thunderbird

## 🔍 Test

Pour tester le template en local :

1. Démarrez Supabase : `supabase start`
2. Créez un compte de test
3. Vérifiez l'email dans Inbucket : http://localhost:54324
4. Vérifiez le rendu sur différents clients email

## 📚 Documentation

- [Supabase Email Templates](https://supabase.com/docs/guides/auth/auth-email-templates)
- [Supabase SMTP Configuration](https://supabase.com/docs/guides/auth/auth-smtp)
