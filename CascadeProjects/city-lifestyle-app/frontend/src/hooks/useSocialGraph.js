import { useState, useEffect, useCallback } from 'react';
import { useQuery, useMutation, useQueryClient } from 'react-query';
import { api } from '../utils/api';

export const useSocialGraph = (userId) => {
  const queryClient = useQueryClient();
  const [error, setError] = useState(null);

  // Fetch connections
  const {
    data: connections = [],
    isLoading: connectionsLoading,
    error: connectionsError
  } = useQuery(
    ['connections', userId],
    () => api.get(`/social/connections/${userId}`).then(res => res.data),
    {
      onError: (err) => setError(err)
    }
  );

  // Fetch pending connections
  const {
    data: pendingConnections = [],
    isLoading: pendingLoading,
    error: pendingError
  } = useQuery(
    ['pending-connections', userId],
    () => api.get(`/social/connections/${userId}/pending`).then(res => res.data),
    {
      onError: (err) => setError(err)
    }
  );

  // Fetch connection recommendations
  const {
    data: recommendations = [],
    isLoading: recommendationsLoading,
    error: recommendationsError
  } = useQuery(
    ['connection-recommendations', userId],
    () => api.get(`/social/connections/${userId}/recommendations`).then(res => res.data),
    {
      onError: (err) => setError(err)
    }
  );

  // Accept connection mutation
  const acceptConnectionMutation = useMutation(
    (connectionId) => api.post(`/social/connections/${connectionId}/accept`),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(['connections', userId]);
        queryClient.invalidateQueries(['pending-connections', userId]);
      },
      onError: (err) => setError(err)
    }
  );

  // Reject connection mutation
  const rejectConnectionMutation = useMutation(
    (connectionId) => api.post(`/social/connections/${connectionId}/reject`),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(['pending-connections', userId]);
      },
      onError: (err) => setError(err)
    }
  );

  // Block user mutation
  const blockUserMutation = useMutation(
    (targetUserId) => api.post(`/social/block/${targetUserId}`),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(['connections', userId]);
        queryClient.invalidateQueries(['pending-connections', userId]);
        queryClient.invalidateQueries(['connection-recommendations', userId]);
      },
      onError: (err) => setError(err)
    }
  );

  // Send connection request mutation
  const sendConnectionRequestMutation = useMutation(
    (targetUserId) => api.post(`/social/connections/request`, { targetUserId }),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(['connection-recommendations', userId]);
      },
      onError: (err) => setError(err)
    }
  );

  // Handler functions
  const acceptConnection = useCallback(
    (connectionId) => acceptConnectionMutation.mutateAsync(connectionId),
    [acceptConnectionMutation]
  );

  const rejectConnection = useCallback(
    (connectionId) => rejectConnectionMutation.mutateAsync(connectionId),
    [rejectConnectionMutation]
  );

  const blockUser = useCallback(
    (targetUserId) => blockUserMutation.mutateAsync(targetUserId),
    [blockUserMutation]
  );

  const sendConnectionRequest = useCallback(
    (targetUserId) => sendConnectionRequestMutation.mutateAsync(targetUserId),
    [sendConnectionRequestMutation]
  );

  // Loading and error states
  const loading =
    connectionsLoading ||
    pendingLoading ||
    recommendationsLoading ||
    acceptConnectionMutation.isLoading ||
    rejectConnectionMutation.isLoading ||
    blockUserMutation.isLoading ||
    sendConnectionRequestMutation.isLoading;

  useEffect(() => {
    const newError =
      connectionsError ||
      pendingError ||
      recommendationsError ||
      acceptConnectionMutation.error ||
      rejectConnectionMutation.error ||
      blockUserMutation.error ||
      sendConnectionRequestMutation.error;

    if (newError) {
      setError(newError);
    }
  }, [
    connectionsError,
    pendingError,
    recommendationsError,
    acceptConnectionMutation.error,
    rejectConnectionMutation.error,
    blockUserMutation.error,
    sendConnectionRequestMutation.error
  ]);

  return {
    connections,
    pendingConnections,
    recommendations,
    loading,
    error,
    acceptConnection,
    rejectConnection,
    blockUser,
    sendConnectionRequest
  };
};
