import React, { useState } from 'react';
import {
  Box,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Avatar,
  TextField,
  IconButton,
  Typography,
  Collapse,
  Button
} from '@mui/material';
import { Send, ExpandMore, ExpandLess } from '@mui/icons-material';
import { formatDistanceToNow } from 'date-fns';

export const CommentSection = ({ activityId, comments, onAddComment }) => {
  const [newComment, setNewComment] = useState('');
  const [expanded, setExpanded] = useState(false);
  const [showAll, setShowAll] = useState(false);

  const visibleComments = showAll ? comments : comments.slice(0, 3);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (newComment.trim()) {
      onAddComment(activityId, newComment.trim());
      setNewComment('');
    }
  };

  const handleExpandClick = () => {
    setExpanded(!expanded);
  };

  const handleShowAllClick = () => {
    setShowAll(!showAll);
  };

  return (
    <Box sx={{ mt: 2 }}>
      <Button
        startIcon={expanded ? <ExpandLess /> : <ExpandMore />}
        onClick={handleExpandClick}
        sx={{ mb: 1 }}
      >
        {expanded ? 'Hide' : 'Show'} Comments ({comments.length})
      </Button>

      <Collapse in={expanded}>
        <List disablePadding>
          {visibleComments.map((comment) => (
            <ListItem
              key={comment.id}
              alignItems="flex-start"
              sx={{ px: 0 }}
            >
              <ListItemAvatar>
                <Avatar
                  src={comment.user.avatar}
                  alt={comment.user.username}
                  sx={{ width: 32, height: 32 }}
                />
              </ListItemAvatar>
              <ListItemText
                primary={
                  <Box
                    sx={{
                      display: 'flex',
                      alignItems: 'baseline',
                      gap: 1
                    }}
                  >
                    <Typography
                      variant="subtitle2"
                      component="span"
                    >
                      {comment.user.username}
                    </Typography>
                    <Typography
                      variant="caption"
                      color="text.secondary"
                    >
                      {formatDistanceToNow(new Date(comment.createdAt))} ago
                    </Typography>
                  </Box>
                }
                secondary={
                  <Typography
                    variant="body2"
                    color="text.primary"
                    sx={{ mt: 0.5 }}
                  >
                    {comment.content}
                  </Typography>
                }
              />
            </ListItem>
          ))}
        </List>

        {comments.length > 3 && (
          <Button
            onClick={handleShowAllClick}
            sx={{ mt: 1 }}
          >
            {showAll ? 'Show Less' : `Show ${comments.length - 3} More Comments`}
          </Button>
        )}

        <Box
          component="form"
          onSubmit={handleSubmit}
          sx={{
            display: 'flex',
            alignItems: 'flex-start',
            gap: 1,
            mt: 2
          }}
        >
          <TextField
            fullWidth
            multiline
            maxRows={4}
            placeholder="Write a comment..."
            value={newComment}
            onChange={(e) => setNewComment(e.target.value)}
            size="small"
          />
          <IconButton
            type="submit"
            color="primary"
            disabled={!newComment.trim()}
          >
            <Send />
          </IconButton>
        </Box>
      </Collapse>
    </Box>
  );
};
