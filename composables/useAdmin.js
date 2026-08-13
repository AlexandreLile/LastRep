import { ref } from 'vue';
import { adminFetch } from '~/composables/useAdminFetch';

export function useAdmin() {
  const isAdmin = ref(false);
  const checked = ref(false);

  const checkAdmin = async () => {
    try {
      const { isAdmin: result } = await adminFetch('/api/admin/check');
      isAdmin.value = result;
    } catch (err) {
      isAdmin.value = false;
    } finally {
      checked.value = true;
    }
  };

  return { isAdmin, checked, checkAdmin };
}
