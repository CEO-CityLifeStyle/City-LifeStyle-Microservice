import React, { useState, useEffect } from 'react';
import {
  Box,
  Avatar,
  Typography,
  Button,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Tabs,
  Tab,
  Badge,
  Tooltip,
  CircularProgress,
  Snackbar
} from '@mui/material';
import {
  PersonAdd,
  Check,
  Close,
  Block,
  MoreVert,
  PeopleAlt
} from '@mui/icons-material';
import { useTheme } from '@mui/material/styles';
import { useAuth } from '../../hooks/useAuth';
import { useSocialGraph } from '../../hooks/useSocialGraph';
import { ConnectionMenu } from './ConnectionMenu';
import { ConnectionCard } from './ConnectionCard';
import { EmptyState } from '../common/EmptyState';

export const SocialGraph = () => {
  const theme = useTheme();
  const { user } = useAuth();
  const {
    connections,
    pendingConnections,
    recommendations,
    loading,
    error,
    acceptConnection,
    rejectConnection,
    blockUser,
    sendConnectionRequest
  } = useSocialGraph();

  const [activeTab, setActiveTab] = useState(0);
  const [selectedUser, setSelectedUser] = useState(null);
  const [menuAnchor, setMenuAnchor] = useState(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '' });

  const handleTabChange = (event, newValue) => {
    setActiveTab(newValue);
  };

  const handleMenuOpen = (event, user) => {
    setSelectedUser(user);
    setMenuAnchor(event.currentTarget);
  };

  const handleMenuClose = () => {
    setMenuAnchor(null);
    setSelectedUser(null);
  };

  const handleAcceptConnection = async (connectionId) => {
    try {
      await acceptConnection(connectionId);
      setSnackbar({
        open: true,
        message: 'Connection request accepted'
      });
    } catch (error) {
      setSnackbar({
        open: true,
        message: 'Failed to accept connection'
      });
    }
  };

  const handleRejectConnection = async (connectionId) => {
    try {
      await rejectConnection(connectionId);
      setSnackbar({
        open: true,
        message: 'Connection request rejected'
      });
    } catch (error) {
      setSnackbar({
        open: true,
        message: 'Failed to reject connection'
      });
    }
  };

  const handleBlockUser = async (userId) => {
    try {
      await blockUser(userId);
      handleMenuClose();
      setSnackbar({
        open: true,
        message: 'User blocked successfully'
      });
    } catch (error) {
      setSnackbar({
        open: true,
        message: 'Failed to block user'
      });
    }
  };

  const handleConnect = async (userId) => {
    try {
      await sendConnectionRequest(userId);
      setSnackbar({
        open: true,
        message: 'Connection request sent'
      });
    } catch (error) {
      setSnackbar({
        open: true,
        message: 'Failed to send connection request'
      });
    }
  };

  const handleSnackbarClose = () => {
    setSnackbar({ ...snackbar, open: false });
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" p={4}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <EmptyState
        icon={<PeopleAlt />}
        title="Error loading connections"
        description="There was a problem loading your connections. Please try again later."
        action={
          <Button variant="contained" color="primary" onClick={() => window.location.reload()}>
            Retry
          </Button>
        }
      />
    );
  }

  return (
    <Box>
      <Tabs
        value={activeTab}
        onChange={handleTabChange}
        indicatorColor="primary"
        textColor="primary"
        variant="fullWidth"
        sx={{ mb: 3 }}
      >
        <Tab
          label={
            <Badge badgeContent={connections.length} color="primary">
              Connections
            </Badge>
          }
        />
        <Tab
          label={
            <Badge badgeContent={pendingConnections.length} color="error">
              Pending
            </Badge>
          }
        />
        <Tab label="Recommendations" />
      </Tabs>

      {activeTab === 0 && (
        <List>
          {connections.length > 0 ? (
            connections.map((connection) => (
              <ConnectionCard
                key={connection.id}
                connection={connection}
                onMenuOpen={handleMenuOpen}
              />
            ))
          ) : (
            <EmptyState
              icon={<PeopleAlt />}
              title="No connections yet"
              description="Start connecting with other users to grow your network"
            />
          )}
        </List>
      )}

      {activeTab === 1 && (
        <List>
          {pendingConnections.length > 0 ? (
            pendingConnections.map((connection) => (
              <ListItem key={connection.id}>
                <ListItemAvatar>
                  <Avatar src={connection.user.avatar} alt={connection.user.username} />
                </ListItemAvatar>
                <ListItemText
                  primary={connection.user.username}
                  secondary={`${connection.metadata.mutualConnections} mutual connections`}
                />
                <ListItemSecondaryAction>
                  <Tooltip title="Accept">
                    <IconButton
                      edge="end"
                      color="primary"
                      onClick={() => handleAcceptConnection(connection.id)}
                    >
                      <Check />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Reject">
                    <IconButton
                      edge="end"
                      color="error"
                      onClick={() => handleRejectConnection(connection.id)}
                    >
                      <Close />
                    </IconButton>
                  </Tooltip>
                </ListItemSecondaryAction>
              </ListItem>
            ))
          ) : (
            <EmptyState
              icon={<PeopleAlt />}
              title="No pending requests"
              description="You don't have any pending connection requests"
            />
          )}
        </List>
      )}

      {activeTab === 2 && (
        <List>
          {recommendations.length > 0 ? (
            recommendations.map((recommendation) => (
              <ListItem key={recommendation.user.id}>
                <ListItemAvatar>
                  <Avatar src={recommendation.user.avatar} alt={recommendation.user.username} />
                </ListItemAvatar>
                <ListItemText
                  primary={recommendation.user.username}
                  secondary={`${recommendation.mutualConnections} mutual connections`}
                />
                <ListItemSecondaryAction>
                  <Button
                    variant="outlined"
                    color="primary"
                    startIcon={<PersonAdd />}
                    onClick={() => handleConnect(recommendation.user.id)}
                  >
                    Connect
                  </Button>
                </ListItemSecondaryAction>
              </ListItem>
            ))
          ) : (
            <EmptyState
              icon={<PeopleAlt />}
              title="No recommendations"
              description="We'll suggest people you might know as you grow your network"
            />
          )}
        </List>
      )}

      <ConnectionMenu
        anchorEl={menuAnchor}
        open={Boolean(menuAnchor)}
        onClose={handleMenuClose}
        onBlock={() => selectedUser && handleBlockUser(selectedUser.id)}
      />

      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={handleSnackbarClose}
        message={snackbar.message}
      />
    </Box>
  );
};
