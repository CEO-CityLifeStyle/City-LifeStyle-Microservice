import React, { useState, useEffect } from 'react';
import {
  Box,
  Grid,
  Card,
  CardMedia,
  CardContent,
  Typography,
  IconButton,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Chip,
  Stack,
  CircularProgress
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  PhotoCamera,
  Collections,
  Article,
  Lock,
  Public,
  Group
} from '@mui/icons-material';
import { useTheme } from '@mui/material/styles';
import { useContent } from '../../hooks/useContent';
import { useAuth } from '../../hooks/useAuth';
import { DropzoneArea } from 'material-ui-dropzone';
import { RichTextEditor } from '../common/RichTextEditor';
import { EmptyState } from '../common/EmptyState';
import { ConfirmDialog } from '../common/ConfirmDialog';

const CONTENT_TYPES = {
  photo: {
    icon: PhotoCamera,
    label: 'Photo',
    accept: 'image/*'
  },
  gallery: {
    icon: Collections,
    label: 'Gallery',
    accept: 'image/*'
  },
  article: {
    icon: Article,
    label: 'Article'
  }
};

export const ContentManager = () => {
  const theme = useTheme();
  const { user } = useAuth();
  const {
    content,
    loading,
    error,
    createContent,
    updateContent,
    deleteContent,
    uploadMedia
  } = useContent();

  const [selectedType, setSelectedType] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [confirmDialogOpen, setConfirmDialogOpen] = useState(false);
  const [selectedContent, setSelectedContent] = useState(null);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    visibility: 'public',
    tags: [],
    files: []
  });
  const [tagInput, setTagInput] = useState('');

  const handleTypeSelect = (type) => {
    setSelectedType(type);
    setDialogOpen(true);
  };

  const handleDialogClose = () => {
    setDialogOpen(false);
    setSelectedType('');
    setSelectedContent(null);
    setFormData({
      title: '',
      description: '',
      visibility: 'public',
      tags: [],
      files: []
    });
  };

  const handleEdit = (content) => {
    setSelectedContent(content);
    setSelectedType(content.type);
    setFormData({
      title: content.title,
      description: content.description,
      visibility: content.visibility,
      tags: content.tags,
      files: content.files
    });
    setDialogOpen(true);
  };

  const handleDelete = (content) => {
    setSelectedContent(content);
    setConfirmDialogOpen(true);
  };

  const handleConfirmDelete = async () => {
    try {
      await deleteContent(selectedContent.id);
      setConfirmDialogOpen(false);
    } catch (error) {
      console.error('Failed to delete content:', error);
    }
  };

  const handleInputChange = (event) => {
    const { name, value } = event.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleTagAdd = () => {
    if (tagInput && !formData.tags.includes(tagInput)) {
      setFormData(prev => ({
        ...prev,
        tags: [...prev.tags, tagInput]
      }));
      setTagInput('');
    }
  };

  const handleTagDelete = (tagToDelete) => {
    setFormData(prev => ({
      ...prev,
      tags: prev.tags.filter(tag => tag !== tagToDelete)
    }));
  };

  const handleFilesChange = (files) => {
    setFormData(prev => ({
      ...prev,
      files
    }));
  };

  const handleSubmit = async () => {
    try {
      const mediaUrls = [];
      if (formData.files.length > 0) {
        for (const file of formData.files) {
          const media = await uploadMedia(file);
          mediaUrls.push(media.url);
        }
      }

      const contentData = {
        type: selectedType,
        title: formData.title,
        description: formData.description,
        visibility: formData.visibility,
        tags: formData.tags,
        media: mediaUrls
      };

      if (selectedContent) {
        await updateContent(selectedContent.id, contentData);
      } else {
        await createContent(contentData);
      }

      handleDialogClose();
    } catch (error) {
      console.error('Failed to save content:', error);
    }
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
        icon={<Error />}
        title="Error loading content"
        description="There was a problem loading your content. Please try again later."
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
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h5">My Content</Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<Add />}
          onClick={() => setDialogOpen(true)}
        >
          Create Content
        </Button>
      </Box>

      <Grid container spacing={3}>
        {content.map((item) => (
          <Grid item xs={12} sm={6} md={4} key={item.id}>
            <Card>
              {item.type === 'photo' && (
                <CardMedia
                  component="img"
                  height="200"
                  image={item.media[0]}
                  alt={item.title}
                />
              )}
              {item.type === 'gallery' && (
                <Box sx={{ position: 'relative', height: 200 }}>
                  <CardMedia
                    component="img"
                    height="200"
                    image={item.media[0]}
                    alt={item.title}
                  />
                  {item.media.length > 1 && (
                    <Box
                      sx={{
                        position: 'absolute',
                        bottom: 8,
                        right: 8,
                        bgcolor: 'rgba(0, 0, 0, 0.6)',
                        color: 'white',
                        px: 1,
                        borderRadius: 1
                      }}
                    >
                      +{item.media.length - 1}
                    </Box>
                  )}
                </Box>
              )}
              <CardContent>
                <Typography variant="h6" noWrap>
                  {item.title}
                </Typography>
                <Typography variant="body2" color="textSecondary" noWrap>
                  {item.description}
                </Typography>
                <Stack direction="row" spacing={1} mt={1}>
                  {item.tags.map((tag) => (
                    <Chip key={tag} label={tag} size="small" />
                  ))}
                </Stack>
                <Box display="flex" justifyContent="space-between" mt={2}>
                  <IconButton size="small" onClick={() => handleEdit(item)}>
                    <Edit />
                  </IconButton>
                  <IconButton size="small" color="error" onClick={() => handleDelete(item)}>
                    <Delete />
                  </IconButton>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Dialog
        open={dialogOpen}
        onClose={handleDialogClose}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          {selectedContent ? 'Edit Content' : 'Create New Content'}
        </DialogTitle>
        <DialogContent>
          <Box mb={2}>
            <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Content Type</InputLabel>
              <Select
                value={selectedType}
                onChange={(e) => setSelectedType(e.target.value)}
                disabled={selectedContent}
              >
                {Object.entries(CONTENT_TYPES).map(([type, { label }]) => (
                  <MenuItem key={type} value={type}>{label}</MenuItem>
                ))}
              </Select>
            </FormControl>

            <TextField
              fullWidth
              label="Title"
              name="title"
              value={formData.title}
              onChange={handleInputChange}
              sx={{ mb: 2 }}
            />

            <TextField
              fullWidth
              label="Description"
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              multiline
              rows={4}
              sx={{ mb: 2 }}
            />

            <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Visibility</InputLabel>
              <Select
                name="visibility"
                value={formData.visibility}
                onChange={handleInputChange}
              >
                <MenuItem value="public">
                  <Box display="flex" alignItems="center">
                    <Public sx={{ mr: 1 }} /> Public
                  </Box>
                </MenuItem>
                <MenuItem value="connections">
                  <Box display="flex" alignItems="center">
                    <Group sx={{ mr: 1 }} /> Connections Only
                  </Box>
                </MenuItem>
                <MenuItem value="private">
                  <Box display="flex" alignItems="center">
                    <Lock sx={{ mr: 1 }} /> Private
                  </Box>
                </MenuItem>
              </Select>
            </FormControl>

            <Box mb={2}>
              <TextField
                fullWidth
                label="Add Tags"
                value={tagInput}
                onChange={(e) => setTagInput(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleTagAdd()}
              />
              <Stack direction="row" spacing={1} mt={1}>
                {formData.tags.map((tag) => (
                  <Chip
                    key={tag}
                    label={tag}
                    onDelete={() => handleTagDelete(tag)}
                  />
                ))}
              </Stack>
            </Box>

            {(selectedType === 'photo' || selectedType === 'gallery') && (
              <DropzoneArea
                acceptedFiles={['image/*']}
                dropzoneText="Drag and drop images here or click"
                onChange={handleFilesChange}
                initialFiles={formData.files}
                maxFileSize={5000000}
                filesLimit={selectedType === 'photo' ? 1 : 10}
              />
            )}

            {selectedType === 'article' && (
              <RichTextEditor
                value={formData.content}
                onChange={(content) => setFormData(prev => ({ ...prev, content }))}
              />
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleDialogClose}>Cancel</Button>
          <Button
            variant="contained"
            color="primary"
            onClick={handleSubmit}
            disabled={!formData.title}
          >
            {selectedContent ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      <ConfirmDialog
        open={confirmDialogOpen}
        title="Delete Content"
        content="Are you sure you want to delete this content? This action cannot be undone."
        onConfirm={handleConfirmDelete}
        onCancel={() => setConfirmDialogOpen(false)}
      />
    </Box>
  );
};
