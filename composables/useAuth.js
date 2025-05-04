export const useAuth = () => {
  const supabase = useSupabaseClient();
  const router = useRouter();

  const email = ref("");
  const password = ref("");
  const errorMessage = ref("");
  const loading = ref(false);

  const translateError = (message) => {
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
      const { error } = await supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value,
        options: {
          // Garder la session active pendant 30 jours
          persistSession: true
        }
      });
      if (error) {
        errorMessage.value = translateError(error.message);
        return;
      }
      router.push("/");
    } catch (error) {
      errorMessage.value = "Une erreur inattendue est survenue.";
      console.error("Erreur de connexion:", error);
    } finally {
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
