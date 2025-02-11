import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Box,
  Typography,
  Chip,
  Avatar
} from '@mui/material';
import {
  Public,
  Group,
  Lock,
  Facebook,
  Twitter,
  LinkedIn,
  WhatsApp
} from '@mui/icons-material';

const SOCIAL_PLATFORMS = [
  { id: 'facebook', name: 'Facebook', icon: Facebook },
  { id: 'twitter', name: 'Twitter', icon: Twitter },
  { id: 'linkedin', name: 'LinkedIn', icon: LinkedIn },
  { id: 'whatsapp', name: 'WhatsApp', icon: WhatsApp }
];

export const ShareDialog = ({ open, activity, onClose, onShare }) => {
  const [message, setMessage] = useState('');
  const [visibility, setVisibility] = useState('connections');
  const [selectedPlatforms, setSelectedPlatforms] = useState([]);

  const handlePlatformToggle = (platformId) => {
    setSelectedPlatforms(prev =>
      prev.includes(platformId)
        ? prev.filter(id => id !== platformId)
        : [...prev, platformId]
    );
  };

  const handleShare = () => {
    onShare({
      message,
      visibility,
      platforms: selectedPlatforms,
      activityId: activity?.id
    });
  };

  const renderActivityPreview = () => {
    if (!activity) return null;

    return (
      <Box sx={{ mt: 2, mb: 3 }}>
        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
          Sharing
        </Typography>
        <Box
          sx={{
            display: 'flex',
            alignItems: 'flex-start',
            gap: 2,
            p: 2,
            bgcolor: 'background.default',
            borderRadius: 1
          }}
        >
          <Avatar
            src={activity.user.avatar}
            alt={activity.user.username}
          />
          <Box>
            <Typography variant="subtitle2">
              {activity.user.username}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {activity.content}
            </Typography>
          </Box>
        </Box>
      </Box>
    );
  };

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
      fullWidth
    >
      <DialogTitle>Share Activity</DialogTitle>
      <DialogContent>
        {renderActivityPreview()}

        <TextField
          fullWidth
          multiline
          rows={3}
          label="Add a message"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          sx={{ mb: 3 }}
        />

        <FormControl fullWidth sx={{ mb: 3 }}>
          <InputLabel>Visibility</InputLabel>
          <Select
            value={visibility}
            onChange={(e) => setVisibility(e.target.value)}
            label="Visibility"
          >
            <MenuItem value="public">
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Public /> Everyone
              </Box>
            </MenuItem>
            <MenuItem value="connections">
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Group /> Connections Only
              </Box>
            </MenuItem>
            <MenuItem value="private">
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Lock /> Only Me
              </Box>
            </MenuItem>
          </Select>
        </FormControl>

        <Typography variant="subtitle2" gutterBottom>
          Share on Social Media
        </Typography>
        <Box
          sx={{
            display: 'flex',
            flexWrap: 'wrap',
            gap: 1
          }}
        >
          {SOCIAL_PLATFORMS.map(platform => {
            const Icon = platform.icon;
            const selected = selectedPlatforms.includes(platform.id);

            return (
              <Chip
                key={platform.id}
                icon={<Icon />}
                label={platform.name}
                onClick={() => handlePlatformToggle(platform.id)}
                color={selected ? 'primary' : 'default'}
                variant={selected ? 'filled' : 'outlined'}
                clickable
              />
            );
          })}
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button
          variant="contained"
          onClick={handleShare}
          disabled={!message.trim()}
        >
          Share
        </Button>
      </DialogActions>
    </Dialog>
  );
};
