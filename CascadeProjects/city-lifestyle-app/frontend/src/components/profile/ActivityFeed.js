import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardHeader,
  CardContent,
  CardActions,
  Avatar,
  Typography,
  IconButton,
  Button,
  Menu,
  MenuItem,
  Skeleton,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar
} from '@mui/material';
import {
  Favorite,
  FavoriteBorder,
  Comment,
  Share,
  MoreVert,
  Event,
  Place,
  Star,
  PhotoCamera
} from '@mui/icons-material';
import { useTheme } from '@mui/material/styles';
import { format, formatDistanceToNow } from 'date-fns';
import { useActivity } from '../../hooks/useActivity';
import { useAuth } from '../../hooks/useAuth';
import { ActivityCard } from './ActivityCard';
import { CommentSection } from './CommentSection';
import { ShareDialog } from './ShareDialog';
import { EmptyState } from '../common/EmptyState';
import { InfiniteScroll } from '../common/InfiniteScroll';

const ACTIVITY_ICONS = {
  event_created: Event,
  place_reviewed: Place,
  content_shared: Share,
  photo_uploaded: PhotoCamera
};

export const ActivityFeed = ({ userId, filter }) => {
  const theme = useTheme();
  const { user } = useAuth();
  const {
    activities,
    loading,
    error,
    hasMore,
    loadMore,
    likeActivity,
    unlikeActivity,
    addComment,
    shareActivity
  } = useActivity(userId, filter);

  const [selectedActivity, setSelectedActivity] = useState(null);
  const [menuAnchor, setMenuAnchor] = useState(null);
  const [shareDialogOpen, setShareDialogOpen] = useState(false);
  const [commentSectionOpen, setCommentSectionOpen] = useState({});

  const handleMenuOpen = (event, activity) => {
    setSelectedActivity(activity);
    setMenuAnchor(event.currentTarget);
  };

  const handleMenuClose = () => {
    setMenuAnchor(null);
    setSelectedActivity(null);
  };

  const handleLike = async (activity) => {
    try {
      if (activity.liked) {
        await unlikeActivity(activity.id);
      } else {
        await likeActivity(activity.id);
      }
    } catch (error) {
      console.error('Failed to toggle like:', error);
    }
  };

  const handleCommentToggle = (activityId) => {
    setCommentSectionOpen(prev => ({
      ...prev,
      [activityId]: !prev[activityId]
    }));
  };

  const handleShare = (activity) => {
    setSelectedActivity(activity);
    setShareDialogOpen(true);
  };

  const handleShareComplete = async (shareData) => {
    try {
      await shareActivity(selectedActivity.id, shareData);
      setShareDialogOpen(false);
    } catch (error) {
      console.error('Failed to share activity:', error);
    }
  };

  const renderActivityContent = (activity) => {
    const Icon = ACTIVITY_ICONS[activity.type] || Event;

    switch (activity.type) {
      case 'event_created':
        return (
          <Box>
            <Box display="flex" alignItems="center" mb={1}>
              <Icon color="primary" sx={{ mr: 1 }} />
              <Typography variant="body1">
                Created a new event: <strong>{activity.target.title}</strong>
              </Typography>
            </Box>
            <Card variant="outlined">
              <Box
                sx={{
                  height: 200,
                  backgroundImage: `url(${activity.target.coverImage})`,
                  backgroundSize: 'cover',
                  backgroundPosition: 'center'
                }}
              />
              <Box p={2}>
                <Typography variant="h6">{activity.target.title}</Typography>
                <Typography variant="body2" color="textSecondary">
                  {format(new Date(activity.target.startTime), 'PPP')}
                </Typography>
              </Box>
            </Card>
          </Box>
        );

      case 'place_reviewed':
        return (
          <Box>
            <Box display="flex" alignItems="center" mb={1}>
              <Icon color="primary" sx={{ mr: 1 }} />
              <Typography variant="body1">
                Reviewed <strong>{activity.target.name}</strong>
              </Typography>
            </Box>
            <Box display="flex" alignItems="center" mb={1}>
              {[...Array(5)].map((_, index) => (
                <Star
                  key={index}
                  color={index < activity.metadata.rating ? 'primary' : 'disabled'}
                />
              ))}
            </Box>
            <Typography variant="body1">{activity.metadata.review}</Typography>
          </Box>
        );

      case 'photo_uploaded':
        return (
          <Box>
            <Box display="flex" alignItems="center" mb={1}>
              <Icon color="primary" sx={{ mr: 1 }} />
              <Typography variant="body1">
                Added {activity.metadata.count} new {activity.metadata.count === 1 ? 'photo' : 'photos'}
              </Typography>
            </Box>
            <Box
              sx={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
                gap: 1
              }}
            >
              {activity.metadata.photos.map((photo, index) => (
                <Box
                  key={index}
                  sx={{
                    height: 150,
                    backgroundImage: `url(${photo})`,
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    borderRadius: 1
                  }}
                />
              ))}
            </Box>
          </Box>
        );

      default:
        return (
          <Typography variant="body1">
            {activity.content}
          </Typography>
        );
    }
  };

  if (loading && !activities.length) {
    return (
      <Box>
        {[...Array(3)].map((_, index) => (
          <Card key={index} sx={{ mb: 2 }}>
            <CardHeader
              avatar={<Skeleton variant="circular" width={40} height={40} />}
              title={<Skeleton variant="text" width="60%" />}
              subheader={<Skeleton variant="text" width="40%" />}
            />
            <CardContent>
              <Skeleton variant="rectangular" height={118} />
            </CardContent>
          </Card>
        ))}
      </Box>
    );
  }

  if (error) {
    return (
      <EmptyState
        icon={<Error />}
        title="Error loading activities"
        description="There was a problem loading the activity feed. Please try again later."
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
      <InfiniteScroll
        hasMore={hasMore}
        loadMore={loadMore}
        loading={loading}
      >
        {activities.map((activity) => (
          <ActivityCard
            key={activity.id}
            activity={activity}
            onLike={() => handleLike(activity)}
            onComment={() => handleCommentToggle(activity.id)}
            onShare={() => handleShare(activity)}
            onMenuOpen={(event) => handleMenuOpen(event, activity)}
          >
            {renderActivityContent(activity)}
            {commentSectionOpen[activity.id] && (
              <CommentSection
                activityId={activity.id}
                comments={activity.comments}
                onAddComment={addComment}
              />
            )}
          </ActivityCard>
        ))}
      </InfiniteScroll>

      <Menu
        anchorEl={menuAnchor}
        open={Boolean(menuAnchor)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={handleMenuClose}>Report</MenuItem>
        {selectedActivity?.userId === user.id && (
          <MenuItem onClick={handleMenuClose}>Delete</MenuItem>
        )}
      </Menu>

      <ShareDialog
        open={shareDialogOpen}
        activity={selectedActivity}
        onClose={() => setShareDialogOpen(false)}
        onShare={handleShareComplete}
      />
    </Box>
  );
};
