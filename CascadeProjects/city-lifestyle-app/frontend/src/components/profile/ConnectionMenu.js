import React from 'react';
import {
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Divider
} from '@mui/material';
import {
  Block,
  PersonRemove,
  Report,
  Message,
  Event,
  Share
} from '@mui/icons-material';

export const ConnectionMenu = ({
  anchorEl,
  open,
  onClose,
  onBlock,
  onRemove,
  onMessage,
  onInvite,
  onShare,
  onReport
}) => {
  return (
    <Menu
      anchorEl={anchorEl}
      open={open}
      onClose={onClose}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'right',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'right',
      }}
    >
      {onMessage && (
        <MenuItem onClick={() => { onMessage(); onClose(); }}>
          <ListItemIcon>
            <Message fontSize="small" />
          </ListItemIcon>
          <ListItemText primary="Send Message" />
        </MenuItem>
      )}

      {onInvite && (
        <MenuItem onClick={() => { onInvite(); onClose(); }}>
          <ListItemIcon>
            <Event fontSize="small" />
          </ListItemIcon>
          <ListItemText primary="Invite to Event" />
        </MenuItem>
      )}

      {onShare && (
        <MenuItem onClick={() => { onShare(); onClose(); }}>
          <ListItemIcon>
            <Share fontSize="small" />
          </ListItemIcon>
          <ListItemText primary="Share Profile" />
        </MenuItem>
      )}

      <Divider />

      {onRemove && (
        <MenuItem onClick={() => { onRemove(); onClose(); }}>
          <ListItemIcon>
            <PersonRemove fontSize="small" color="warning" />
          </ListItemIcon>
          <ListItemText primary="Remove Connection" />
        </MenuItem>
      )}

      {onBlock && (
        <MenuItem onClick={() => { onBlock(); onClose(); }}>
          <ListItemIcon>
            <Block fontSize="small" color="error" />
          </ListItemIcon>
          <ListItemText primary="Block User" />
        </MenuItem>
      )}

      {onReport && (
        <MenuItem onClick={() => { onReport(); onClose(); }}>
          <ListItemIcon>
            <Report fontSize="small" color="error" />
          </ListItemIcon>
          <ListItemText primary="Report User" />
        </MenuItem>
      )}
    </Menu>
  );
};
