import { useState, useEffect, useCallback } from 'react';
import { useQuery, useMutation, useQueryClient } from 'react-query';
import { api } from '../utils/api';

export const useActivity = (userId, filter = {}) => {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [error, setError] = useState(null);

  // Fetch activities
  const {
    data: activitiesData,
    isLoading,
    error: fetchError
  } = useQuery(
    ['activities', userId, filter, page],
    () => api.get(`/activities/${userId}`, { params: { ...filter, page } })
      .then(res => res.data),
    {
      keepPreviousData: true,
      onSuccess: (data) => {
        setHasMore(data.hasMore);
      },
      onError: (err) => setError(err)
    }
  );

  // Like activity mutation
  const likeActivityMutation = useMutation(
    (activityId) => api.post(`/activities/${activityId}/like`),
    {
      onSuccess: (_, activityId) => {
        queryClient.invalidateQueries(['activities', userId]);
      },
      onError: (err) => setError(err)
    }
  );

  // Unlike activity mutation
  const unlikeActivityMutation = useMutation(
    (activityId) => api.delete(`/activities/${activityId}/like`),
    {
      onSuccess: (_, activityId) => {
        queryClient.invalidateQueries(['activities', userId]);
      },
      onError: (err) => setError(err)
    }
  );

  // Add comment mutation
  const addCommentMutation = useMutation(
    ({ activityId, comment }) => api.post(`/activities/${activityId}/comments`, { content: comment }),
    {
      onSuccess: (_, { activityId }) => {
        queryClient.invalidateQueries(['activities', userId]);
      },
      onError: (err) => setError(err)
    }
  );

  // Share activity mutation
  const shareActivityMutation = useMutation(
    ({ activityId, shareData }) => api.post(`/activities/${activityId}/share`, shareData),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(['activities', userId]);
      },
      onError: (err) => setError(err)
    }
  );

  // Handler functions
  const loadMore = useCallback(() => {
    if (hasMore && !isLoading) {
      setPage(prev => prev + 1);
    }
  }, [hasMore, isLoading]);

  const likeActivity = useCallback(
    (activityId) => likeActivityMutation.mutateAsync(activityId),
    [likeActivityMutation]
  );

  const unlikeActivity = useCallback(
    (activityId) => unlikeActivityMutation.mutateAsync(activityId),
    [unlikeActivityMutation]
  );

  const addComment = useCallback(
    (activityId, comment) => addCommentMutation.mutateAsync({ activityId, comment }),
    [addCommentMutation]
  );

  const shareActivity = useCallback(
    (activityId, shareData) => shareActivityMutation.mutateAsync({ activityId, shareData }),
    [shareActivityMutation]
  );

  // Combine activities from all pages
  const activities = activitiesData?.activities || [];

  // Update error state
  useEffect(() => {
    const newError =
      fetchError ||
      likeActivityMutation.error ||
      unlikeActivityMutation.error ||
      addCommentMutation.error ||
      shareActivityMutation.error;

    if (newError) {
      setError(newError);
    }
  }, [
    fetchError,
    likeActivityMutation.error,
    unlikeActivityMutation.error,
    addCommentMutation.error,
    shareActivityMutation.error
  ]);

  return {
    activities,
    loading: isLoading,
    error,
    hasMore,
    loadMore,
    likeActivity,
    unlikeActivity,
    addComment,
    shareActivity
  };
};
