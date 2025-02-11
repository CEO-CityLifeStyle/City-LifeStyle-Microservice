import React from 'react';
import {
  ListItem,
  ListItemAvatar,
  ListItemText,
  ListItemSecondaryAction,
  Avatar,
  IconButton,
  Typography,
  Box,
  Chip,
  Tooltip
} from '@mui/material';
import {
  MoreVert,
  Event,
  Place,
  Star
} from '@mui/icons-material';
import { formatDistanceToNow } from 'date-fns';

export const ConnectionCard = ({ connection, onMenuOpen }) => {
  const { user, metadata } = connection;

  const renderMutualActivities = () => {
    const activities = [];

    if (metadata.mutualEvents > 0) {
      activities.push(
        <Tooltip key="events" title={`${metadata.mutualEvents} mutual events`}>
          <Chip
            icon={<Event />}
            label={metadata.mutualEvents}
            size="small"
            variant="outlined"
          />
        </Tooltip>
      );
    }

    if (metadata.mutualPlaces > 0) {
      activities.push(
        <Tooltip key="places" title={`${metadata.mutualPlaces} mutual places`}>
          <Chip
            icon={<Place />}
            label={metadata.mutualPlaces}
            size="small"
            variant="outlined"
          />
        </Tooltip>
      );
    }

    if (metadata.mutualInterests > 0) {
      activities.push(
        <Tooltip key="interests" title={`${metadata.mutualInterests} mutual interests`}>
          <Chip
            icon={<Star />}
            label={metadata.mutualInterests}
            size="small"
            variant="outlined"
          />
        </Tooltip>
      );
    }

    return activities;
  };

  return (
    <ListItem alignItems="flex-start">
      <ListItemAvatar>
        <Avatar
          src={user.avatar}
          alt={user.username}
          sx={{ width: 50, height: 50 }}
        />
      </ListItemAvatar>
      <ListItemText
        primary={
          <Typography variant="subtitle1" component="div">
            {user.username}
          </Typography>
        }
        secondary={
          <Box>
            <Typography
              variant="body2"
              color="text.secondary"
              component="div"
              sx={{ mb: 0.5 }}
            >
              Connected {formatDistanceToNow(new Date(connection.createdAt))} ago
            </Typography>
            <Box sx={{ display: 'flex', gap: 1 }}>
              {renderMutualActivities()}
            </Box>
          </Box>
        }
      />
      <ListItemSecondaryAction>
        <IconButton
          edge="end"
          onClick={(event) => onMenuOpen(event, user)}
        >
          <MoreVert />
        </IconButton>
      </ListItemSecondaryAction>
    </ListItem>
  );
};
