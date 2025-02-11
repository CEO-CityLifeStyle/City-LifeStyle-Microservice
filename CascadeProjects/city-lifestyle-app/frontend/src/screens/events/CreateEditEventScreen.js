import React, { useState, useEffect } from 'react';
import {
  View,
  ScrollView,
  StyleSheet,
  Alert,
  KeyboardAvoidingView,
  Platform
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { useDispatch, useSelector } from 'react-redux';
import {
  createEvent,
  updateEvent,
  selectEventDetail,
  selectEventLoading,
  selectEventError
} from '../../store/slices/eventsSlice';
import FormInput from '../../components/common/FormInput';
import FormDatePicker from '../../components/common/FormDatePicker';
import FormImagePicker from '../../components/common/FormImagePicker';
import FormLocationPicker from '../../components/common/FormLocationPicker';
import CategoryPicker from '../../components/events/CategoryPicker';
import TagInput from '../../components/common/TagInput';
import Button from '../../components/common/Button';
import { useTheme } from '../../hooks/useTheme';
import { useForm } from '../../hooks/useForm';
import { uploadImages } from '../../utils/imageUtils';
import { SCREEN_PADDING } from '../../constants/layout';

const CreateEditEventScreen = () => {
  const route = useRoute();
  const navigation = useNavigation();
  const dispatch = useDispatch();
  const { colors } = useTheme();

  // Get eventId from route params if editing
  const { eventId } = route.params || {};
  const isEditing = !!eventId;

  // Redux
  const event = useSelector(state => selectEventDetail(state, eventId));
  const loading = useSelector(selectEventLoading);
  const error = useSelector(selectEventError);

  // Form state
  const { values, setValues, errors, setErrors, handleChange, validate } = useForm({
    initialValues: {
      title: '',
      description: '',
      category: '',
      startTime: new Date(),
      endTime: new Date(),
      placeId: '',
      capacity: '100',
      price: '0',
      tags: [],
      images: [],
      settings: {
        isPrivate: false,
        requiresApproval: false,
        allowWaitlist: true,
        maxTicketsPerUser: 4
      }
    },
    validationRules: {
      title: { required: true, minLength: 3 },
      description: { required: true, minLength: 10 },
      category: { required: true },
      placeId: { required: true },
      capacity: { required: true, min: 1 },
      price: { required: true, min: 0 },
      images: { minLength: 1 }
    }
  });

  // Effects
  useEffect(() => {
    if (isEditing && event) {
      setValues({
        title: event.title,
        description: event.description,
        category: event.category,
        startTime: new Date(event.startTime),
        endTime: new Date(event.endTime),
        placeId: event.placeId,
        capacity: event.capacity.toString(),
        price: event.price.amount.toString(),
        tags: event.tags,
        images: event.images,
        settings: event.settings
      });
    }
  }, [isEditing, event]);

  // Handlers
  const handleSubmit = async () => {
    if (!validate()) {
      return;
    }

    try {
      const formData = {
        ...values,
        capacity: parseInt(values.capacity),
        price: {
          amount: parseFloat(values.price),
          currency: 'USD' // TODO: Make configurable
        }
      };

      // Upload images if new ones were added
      const newImages = values.images.filter(img => !img.startsWith('http'));
      if (newImages.length > 0) {
        const uploadedUrls = await uploadImages(newImages);
        formData.images = [
          ...values.images.filter(img => img.startsWith('http')),
          ...uploadedUrls
        ];
      }

      if (isEditing) {
        await dispatch(updateEvent({ eventId, updates: formData })).unwrap();
        Alert.alert('Success', 'Event updated successfully');
      } else {
        const newEvent = await dispatch(createEvent(formData)).unwrap();
        Alert.alert('Success', 'Event created successfully');
        navigation.replace('EventDetail', { eventId: newEvent.id });
      }
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  };

  return (
    <KeyboardAvoidingView
      style={[styles.container, { backgroundColor: colors.background }]}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        <FormImagePicker
          images={values.images}
          onChange={images => handleChange('images', images)}
          error={errors.images}
          style={styles.imagePicker}
        />

        <View style={styles.form}>
          <FormInput
            label="Title"
            value={values.title}
            onChangeText={text => handleChange('title', text)}
            error={errors.title}
            maxLength={100}
          />

          <FormInput
            label="Description"
            value={values.description}
            onChangeText={text => handleChange('description', text)}
            error={errors.description}
            multiline
            numberOfLines={4}
            maxLength={1000}
          />

          <CategoryPicker
            value={values.category}
            onChange={category => handleChange('category', category)}
            error={errors.category}
          />

          <FormDatePicker
            label="Start Time"
            value={values.startTime}
            onChange={date => handleChange('startTime', date)}
            minimumDate={new Date()}
          />

          <FormDatePicker
            label="End Time"
            value={values.endTime}
            onChange={date => handleChange('endTime', date)}
            minimumDate={values.startTime}
          />

          <FormLocationPicker
            label="Location"
            value={values.placeId}
            onChange={place => handleChange('placeId', place.id)}
            error={errors.placeId}
          />

          <FormInput
            label="Capacity"
            value={values.capacity}
            onChangeText={text => handleChange('capacity', text)}
            error={errors.capacity}
            keyboardType="numeric"
          />

          <FormInput
            label="Price"
            value={values.price}
            onChangeText={text => handleChange('price', text)}
            error={errors.price}
            keyboardType="decimal-pad"
            prefix="$"
          />

          <TagInput
            label="Tags"
            tags={values.tags}
            onChange={tags => handleChange('tags', tags)}
            suggestions={['music', 'art', 'food', 'sports', 'education']}
          />

          <View style={styles.settings}>
            {/* Add settings toggles here */}
          </View>

          <Button
            title={isEditing ? 'Update Event' : 'Create Event'}
            onPress={handleSubmit}
            loading={loading}
            disabled={loading}
            style={styles.submitButton}
          />
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
  },
  imagePicker: {
    height: 200,
  },
  form: {
    padding: SCREEN_PADDING,
    gap: 16,
  },
  settings: {
    marginTop: 16,
    gap: 12,
  },
  submitButton: {
    marginTop: 24,
    marginBottom: Platform.OS === 'ios' ? 40 : 24,
  },
});

export default CreateEditEventScreen;
