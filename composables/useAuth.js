export const useAuth = () => {
  const supabase = useSupabaseClient();
  const router = useRouter();

  const email = ref("");
  const password = ref("");
  const errorMessage = ref("");
  const loading = ref(false);

  const translateError = (message) => {
    // Vérifier les erreurs d'email déjà utilisé (plusieurs variantes possibles)
    if (
      message.includes("User already registered") ||
      message.includes("already been registered") ||
      message.includes("already exists") ||
      message.includes("email address has already been registered") ||
      message === "User already registered"
    ) {
      return "email_exists";
    }
    
    switch (message) {
      case "Invalid login credentials":
        return "Email ou mot de passe incorrect.";
      case "Email not confirmed":
        return "Votre adresse email n'est pas confirmée.";
      case "User not found":
        return "Utilisateur non trouvé.";
      default:
        return "Une erreur est survenue. Veuillez réessayer.";
    }
  };

  const handleLogin = async () => {
    errorMessage.value = "";
    loading.value = true;
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value,
        options: {
          // Garder la session active pendant 30 jours
          persistSession: true
        }
      });
      
      if (error) {
        errorMessage.value = translateError(error.message);
        loading.value = false;
        return;
      }

      // Attendre que la session soit confirmée
      if (data.session) {
        // Attendre un court instant pour s'assurer que la session est bien établie
        await new Promise(resolve => setTimeout(resolve, 300));
        
        // Vérifier à nouveau la session pour confirmer
        const { data: { session: confirmedSession } } = await supabase.auth.getSession();
        
        if (confirmedSession) {
          // Utiliser navigateTo au lieu de router.push pour une meilleure intégration avec Nuxt
          await navigateTo("/");
          loading.value = false;
        } else {
          // Si la session n'est pas confirmée, écouter l'événement SIGNED_IN comme fallback
          const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
            if (event === 'SIGNED_IN' && session) {
              subscription.unsubscribe();
              navigateTo("/").then(() => {
                loading.value = false;
              });
            }
          });
          
          // Timeout après 3 secondes si la session n'arrive pas
          setTimeout(() => {
            subscription.unsubscribe();
            if (loading.value) {
              errorMessage.value = "La session n'a pas pu être établie. Veuillez réessayer.";
              loading.value = false;
            }
          }, 3000);
        }
      } else {
        // Si pas de session immédiate, écouter l'événement SIGNED_IN
        const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
          if (event === 'SIGNED_IN' && session) {
            subscription.unsubscribe();
            navigateTo("/").then(() => {
              loading.value = false;
            });
          }
        });
        
        // Timeout après 3 secondes si la session n'arrive pas
        setTimeout(() => {
          subscription.unsubscribe();
          if (loading.value) {
            errorMessage.value = "La session n'a pas pu être établie. Veuillez réessayer.";
            loading.value = false;
          }
        }, 3000);
      }
    } catch (error) {
      errorMessage.value = "Une erreur inattendue est survenue.";
      console.error("Erreur de connexion:", error);
      loading.value = false;
    }
  };

  const handleRegister = async () => {
    errorMessage.value = "";
    loading.value = true;
    try {
      const { error } = await supabase.auth.signUp({
        email: email.value,
        password: password.value,
      });

      if (error) {
        errorMessage.value = translateError(error.message);
        return;
      }

      router.push("/check-email");
    } catch (error) {
      errorMessage.value = "Une erreur inattendue est survenue.";
      console.error("Erreur d'inscription:", error);
    } finally {
      loading.value = false;
    }
  };

  const handleGoogleLogin = async () => {
    errorMessage.value = "";
    loading.value = true;
    try {
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/auth/callback`,
          queryParams: {
            access_type: 'offline',
            prompt: 'consent'
          }
        }
      });
      
      if (error) {
        errorMessage.value = translateError(error.message);
        return;
      }
    } catch (error) {
      errorMessage.value = "Une erreur inattendue est survenue.";
      console.error("Erreur de connexion Google:", error);
    } finally {
      loading.value = false;
    }
  };

  return {
    email,
    password,
    errorMessage,
    loading,
    handleLogin,
    handleRegister,
    handleGoogleLogin,
  };
};
