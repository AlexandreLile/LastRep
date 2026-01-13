# 🔧 Configuration DNS Resend pour lastrep.fr

## 📋 Enregistrements DNS à Ajouter

Vous devez ajouter ces enregistrements DNS **chez votre registrar** (OVH, Cloudflare, etc.) pour le domaine **`lastrep.fr`** (domaine racine).

---

## ✅ Enregistrements à Ajouter

### 1. DKIM (Domain Verification)

**Type** : `TXT`  
**Nom** : `resend._domainkey` ← **C'est ce qui vient AVANT .lastrep.fr**  
**Valeur** : `p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC3oJyezYxh7TxCQTcTlQoIIaLmbFphsoFcK/6jF6bWua8BNO5PpV+2JvtRExtMW5kaHeVyTnwyZDk9+m+BHriWsSl09/b7v4gsguC6bFiz+0KoNdZRMpfq/8vzDwRrEVIZ+nXUmN1mZWYm/8TAsurS8LIlav+BHvH+AF7TudfMMQIDAQAB`  
**TTL** : Auto (ou 3600)

**Explication** :
- Le **Nom** est : `resend._domainkey`
- Le nom complet sera automatiquement : `resend._domainkey.lastrep.fr`
- Vous n'avez qu'à mettre `resend._domainkey` dans le champ "Nom" ou "Sous-domaine"

---

### 2. SPF (Enable Sending)

**Type** : `TXT`  
**Nom** : `send` ← **C'est ce qui vient AVANT .lastrep.fr**  
**Valeur** : `v=spf1 include:amazonses.com ~all`  
**TTL** : Auto (ou 3600)

**Explication** :
- Le **Nom** est : `send`
- Le nom complet sera automatiquement : `send.lastrep.fr`
- **Alternative** : Si votre registrar utilise `@` pour le domaine racine, vous pouvez utiliser `@` au lieu de `send`
  - Avec `@` : l'enregistrement sera pour `lastrep.fr` directement
  - Avec `send` : l'enregistrement sera pour `send.lastrep.fr`

---

### 3. MX (Enable Sending) - Optionnel mais recommandé

**Type** : `MX`  
**Nom** : `send` ← **C'est ce qui vient AVANT .lastrep.fr**  
**Valeur** : `feedback-smtp.eu-west-1.amazonses.com`  
**Priorité** : `10`  
**TTL** : Auto (ou 3600)

**Explication** :
- Le **Nom** est : `send`
- Le nom complet sera automatiquement : `send.lastrep.fr`
- Cet enregistrement permet de recevoir les bounces et feedbacks.

---

### 4. DMARC (Optionnel mais recommandé)

**Type** : `TXT`  
**Nom** : `_dmarc` ← **C'est ce qui vient AVANT .lastrep.fr**  
**Valeur** : `v=DMARC1; p=none;`  
**TTL** : Auto (ou 3600)

**Explication** :
- Le **Nom** est : `_dmarc`
- Le nom complet sera automatiquement : `_dmarc.lastrep.fr`
- Améliore la réputation de votre domaine et réduit les risques de spam.

---

## 📍 Où Ajouter ces Enregistrements

### Chez OVH

1. Allez sur [ovh.com](https://www.ovh.com)
2. Connectez-vous à votre compte
3. Allez dans **Web Cloud** → **Domaines**
4. Cliquez sur **`lastrep.fr`**
5. Cliquez sur **Zone DNS**
6. Cliquez sur **Ajouter une entrée**
7. Ajoutez chaque enregistrement un par un

**Format OVH :**
- **Sous-domaine** : `resend._domainkey` ← **Mettez juste ça, OVH ajoutera automatiquement .lastrep.fr**
- **Sous-domaine** : `send` ← **Mettez juste ça**
- **Sous-domaine** : `_dmarc` ← **Mettez juste ça**
- **Type** : Sélectionnez dans le menu déroulant (TXT ou MX)
- **Valeur** : Collez la valeur complète

**Exemple visuel OVH :**
```
┌─────────────────────────────────────┐
│ Ajouter une entrée                  │
├─────────────────────────────────────┤
│ Sous-domaine: resend._domainkey     │ ← Vous tapez ça
│ Type: TXT                           │
│ Valeur: p=MIGfMA0GCSqGSIb3...       │ ← Vous collez ça
│ TTL: 3600                           │
│                                     │
│ [Ajouter]                           │
└─────────────────────────────────────┘

Résultat : resend._domainkey.lastrep.fr (automatique)
```

---

### Chez Cloudflare

1. Allez sur [cloudflare.com](https://www.cloudflare.com)
2. Connectez-vous
3. Sélectionnez votre domaine **`lastrep.fr`**
4. Allez dans **DNS** → **Records**
5. Cliquez sur **Add record**
6. Ajoutez chaque enregistrement

**Format Cloudflare :**
- **Type** : Sélectionnez `TXT` ou `MX`
- **Name** : 
  - `resend._domainkey` ← **Mettez juste ça, Cloudflare ajoutera automatiquement .lastrep.fr**
  - `send` ← **Mettez juste ça**
  - `_dmarc` ← **Mettez juste ça**
- **Content** : Collez la valeur complète
- **TTL** : Auto

**Exemple visuel Cloudflare :**
```
┌─────────────────────────────────────┐
│ Add record                          │
├─────────────────────────────────────┤
│ Type: TXT                           │
│ Name: resend._domainkey            │ ← Vous tapez ça
│ Content: p=MIGfMA0GCSqGSIb3...       │ ← Vous collez ça
│ TTL: Auto                           │
│                                     │
│ [Save]                              │
└─────────────────────────────────────┘

Résultat : resend._domainkey.lastrep.fr (automatique)
```

---

### Chez un autre Registrar

La procédure est similaire :
1. Connectez-vous à votre compte
2. Trouvez la section **DNS** ou **Zone DNS**
3. Ajoutez les enregistrements un par un
4. Sauvegardez

---

## 📝 Exemple Complet pour OVH

Voici exactement ce que vous devez ajouter dans OVH :

**⚠️ RAPPEL : Le "Sous-domaine" est ce qui vient AVANT .lastrep.fr**

### Enregistrement 1 : DKIM
```
Type: TXT
Sous-domaine: resend._domainkey  ← Juste ça, OVH ajoute .lastrep.fr automatiquement
Valeur: p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC3oJyezYxh7TxCQTcTlQoIIaLmbFphsoFcK/6jF6bWua8BNO5PpV+2JvtRExtMW5kaHeVyTnwyZDk9+m+BHriWsSl09/b7v4gsguC6bFiz+0KoNdZRMpfq/8vzDwRrEVIZ+nXUmN1mZWYm/8TAsurS8LIlav+BHvH+AF7TudfMMQIDAQAB
TTL: 3600

Résultat final : resend._domainkey.lastrep.fr
```

### Enregistrement 2 : SPF
```
Type: TXT
Sous-domaine: send  ← Juste ça
Valeur: v=spf1 include:amazonses.com ~all
TTL: 3600

Résultat final : send.lastrep.fr
```

### Enregistrement 3 : MX
```
Type: MX
Sous-domaine: send  ← Juste ça
Valeur: feedback-smtp.eu-west-1.amazonses.com
Priorité: 10
TTL: 3600

Résultat final : send.lastrep.fr
```

### Enregistrement 4 : DMARC
```
Type: TXT
Sous-domaine: _dmarc  ← Juste ça
Valeur: v=DMARC1; p=none;
TTL: 3600

Résultat final : _dmarc.lastrep.fr
```

## 💡 Résumé Simple

**Dans le champ "Nom" ou "Sous-domaine", vous mettez :**
- ✅ `resend._domainkey` (pas `resend._domainkey.lastrep.fr`)
- ✅ `send` (pas `send.lastrep.fr`)
- ✅ `_dmarc` (pas `_dmarc.lastrep.fr`)

**Votre registrar ajoutera automatiquement `.lastrep.fr` à la fin !**

---

## ⏱️ Après l'Ajout

1. **Attendez la propagation DNS** (5-30 minutes généralement, jusqu'à 48h max)
2. **Retournez dans Resend** → Domains
3. Cliquez sur **"Verify"** ou attendez la vérification automatique
4. Une fois vérifié, vous verrez un ✅ vert à côté de votre domaine

---

## ✅ Checklist

- [ ] Enregistrement DKIM ajouté (`resend._domainkey`)
- [ ] Enregistrement SPF ajouté (`send` ou `@`)
- [ ] Enregistrement MX ajouté (`send` ou `@`)
- [ ] Enregistrement DMARC ajouté (`_dmarc`)
- [ ] Tous les enregistrements sauvegardés
- [ ] Attendu la propagation DNS (5-30 min)
- [ ] Domaine vérifié dans Resend (✅ vert)

---

## 🐛 Dépannage

### Le domaine ne se vérifie pas

1. **Vérifiez que les enregistrements sont corrects** :
   - Vérifiez qu'il n'y a pas d'espaces supplémentaires
   - Vérifiez que les valeurs sont exactement comme indiqué
   - Vérifiez que le type est correct (TXT, MX)

2. **Vérifiez la propagation DNS** :
   - Utilisez [mxtoolbox.com](https://mxtoolbox.com) pour vérifier
   - Tapez `resend._domainkey.lastrep.fr` dans "DNS Lookup"
   - Vérifiez que l'enregistrement apparaît

3. **Attendez un peu** :
   - La propagation peut prendre jusqu'à 48h
   - Généralement 5-30 minutes

### Erreur "Domain not verified"

- Vérifiez que vous avez bien ajouté TOUS les enregistrements
- Vérifiez que les valeurs sont exactes (copier-coller)
- Attendez la propagation DNS

---

## 🔍 Vérification des Enregistrements

### Vérifier avec des outils en ligne

1. **MXToolbox** : [mxtoolbox.com](https://mxtoolbox.com)
   - Tapez `resend._domainkey.lastrep.fr` → DNS Lookup
   - Vérifiez que l'enregistrement TXT apparaît

2. **DNS Checker** : [dnschecker.org](https://dnschecker.org)
   - Vérifiez la propagation mondiale

3. **Dans votre terminal** :
   ```bash
   dig TXT resend._domainkey.lastrep.fr
   dig TXT send.lastrep.fr
   dig MX send.lastrep.fr
   dig TXT _dmarc.lastrep.fr
   ```

---

## 💡 Notes Importantes

1. **Domaine racine** : Ajoutez ces enregistrements pour `lastrep.fr`, pas `app.lastrep.fr`
2. **Propagation** : Peut prendre jusqu'à 48h, mais généralement 5-30 minutes
3. **Vérification** : Resend vérifie automatiquement, mais vous pouvez forcer la vérification
4. **Une fois vérifié** : Changez le sender email dans Supabase pour `noreply@lastrep.fr`

---

## 🚀 Prochaines Étapes

Une fois le domaine vérifié dans Resend :

1. ✅ Retournez dans **Supabase** → Authentication → Settings → SMTP Settings
2. ✅ Changez le **Sender email** de `onboarding@resend.dev` à `noreply@lastrep.fr`
3. ✅ Sauvegardez
4. ✅ Testez en créant un compte de test

---

## 📞 Besoin d'aide ?

Si vous avez des difficultés :
- Vérifiez la documentation Resend : [resend.com/docs](https://resend.com/docs)
- Contactez le support Resend (très réactif)
- Vérifiez les logs dans Resend Dashboard → Logs
