import React from 'react';
import {
  Card,
  CardHeader,
  CardContent,
  CardActions,
  Avatar,
  IconButton,
  Typography,
  Box,
  Tooltip,
  Button
} from '@mui/material';
import {
  Favorite,
  FavoriteBorder,
  Comment,
  Share,
  MoreVert
} from '@mui/icons-material';
import { formatDistanceToNow } from 'date-fns';

export const ActivityCard = ({
  activity,
  onLike,
  onComment,
  onShare,
  onMenuOpen,
  children
}) => {
  const {
    user,
    createdAt,
    interactions,
    liked
  } = activity;

  return (
    <Card sx={{ mb: 2 }}>
      <CardHeader
        avatar={
          <Avatar
            src={user.avatar}
            alt={user.username}
            sx={{ width: 40, height: 40 }}
          />
        }
        action={
          <IconButton onClick={(event) => onMenuOpen(event, activity)}>
            <MoreVert />
          </IconButton>
        }
        title={
          <Typography variant="subtitle1">
            {user.username}
          </Typography>
        }
        subheader={
          <Typography variant="body2" color="text.secondary">
            {formatDistanceToNow(new Date(createdAt))} ago
          </Typography>
        }
      />

      <CardContent>
        {children}
      </CardContent>

      <CardActions disableSpacing>
        <Box sx={{ display: 'flex', alignItems: 'center', mr: 2 }}>
          <Tooltip title={liked ? 'Unlike' : 'Like'}>
            <IconButton
              onClick={onLike}
              color={liked ? 'primary' : 'default'}
            >
              {liked ? <Favorite /> : <FavoriteBorder />}
            </IconButton>
          </Tooltip>
          <Typography variant="body2" color="text.secondary">
            {interactions.likes}
          </Typography>
        </Box>

        <Box sx={{ display: 'flex', alignItems: 'center', mr: 2 }}>
          <Tooltip title="Comment">
            <IconButton onClick={onComment}>
              <Comment />
            </IconButton>
          </Tooltip>
          <Typography variant="body2" color="text.secondary">
            {interactions.comments}
          </Typography>
        </Box>

        <Box sx={{ display: 'flex', alignItems: 'center' }}>
          <Tooltip title="Share">
            <IconButton onClick={onShare}>
              <Share />
            </IconButton>
          </Tooltip>
          <Typography variant="body2" color="text.secondary">
            {interactions.shares}
          </Typography>
        </Box>
      </CardActions>
    </Card>
  );
};
