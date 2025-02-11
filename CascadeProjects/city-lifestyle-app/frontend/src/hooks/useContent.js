import { useState, useEffect, useCallback } from 'react';
import { useQuery, useMutation, useQueryClient } from 'react-query';
import { api } from '../utils/api';

export const useContent = (userId) => {
  const queryClient = useQueryClient();
  const [error, setError] = useState(null);

  // Fetch user content
  const {
    data: content = [],
    isLoading,
    error: fetchError
  } = useQuery(
    ['content', userId],
    () => api.get(`/content/${userId}`).then(res => res.data),
    {
      onError: (err) => setError(err)
    }
  );

  // Create content mutation
  const createContentMutation = useMutation(
    (contentData) => api.post('/content', contentData),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(['content', userId]);
      },
      onError: (err) => setError(err)
    }
  );

  // Update content mutation
  const updateContentMutation = useMutation(
    ({ contentId, updates }) => api.put(`/content/${contentId}`, updates),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(['content', userId]);
      },
      onError: (err) => setError(err)
    }
  );

  // Delete content mutation
  const deleteContentMutation = useMutation(
    (contentId) => api.delete(`/content/${contentId}`),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(['content', userId]);
      },
      onError: (err) => setError(err)
    }
  );

  // Upload media mutation
  const uploadMediaMutation = useMutation(
    (file) => {
      const formData = new FormData();
      formData.append('file', file);
      return api.post('/content/media', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
    },
    {
      onError: (err) => setError(err)
    }
  );

  // Handler functions
  const createContent = useCallback(
    (contentData) => createContentMutation.mutateAsync(contentData),
    [createContentMutation]
  );

  const updateContent = useCallback(
    (contentId, updates) => updateContentMutation.mutateAsync({ contentId, updates }),
    [updateContentMutation]
  );

  const deleteContent = useCallback(
    (contentId) => deleteContentMutation.mutateAsync(contentId),
    [deleteContentMutation]
  );

  const uploadMedia = useCallback(
    (file) => uploadMediaMutation.mutateAsync(file),
    [uploadMediaMutation]
  );

  // Update error state
  useEffect(() => {
    const newError =
      fetchError ||
      createContentMutation.error ||
      updateContentMutation.error ||
      deleteContentMutation.error ||
      uploadMediaMutation.error;

    if (newError) {
      setError(newError);
    }
  }, [
    fetchError,
    createContentMutation.error,
    updateContentMutation.error,
    deleteContentMutation.error,
    uploadMediaMutation.error
  ]);

  return {
    content,
    loading: isLoading ||
      createContentMutation.isLoading ||
      updateContentMutation.isLoading ||
      deleteContentMutation.isLoading ||
      uploadMediaMutation.isLoading,
    error,
    createContent,
    updateContent,
    deleteContent,
    uploadMedia
  };
};
