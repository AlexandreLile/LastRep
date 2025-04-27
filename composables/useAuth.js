export const useAuth = () => {
  const supabase = useSupabaseClient();
  const router = useRouter();

  const email = ref("");
  const password = ref("");
  const errorMessage = ref("");

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
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value,
      });
      if (error) {
        errorMessage.value = translateError(error.message);
        return;
      }
      router.push("/");
    } catch (error) {
      errorMessage.value = "Une erreur inattendue est survenue.";
      console.error("Erreur de connexion:", error);
    }
  };

  const handleRegister = async () => {
    errorMessage.value = "";
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
    }
  };

  return {
    email,
    password,
    errorMessage,
    handleLogin,
    handleRegister,
  };
};
