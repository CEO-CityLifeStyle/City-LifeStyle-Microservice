import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Image,
  TouchableOpacity,
  Modal,
  FlatList,
  Dimensions,
  Platform
} from 'react-native';
import { useTheme } from '../../hooks/useTheme';
import Icon from '../common/Icon';
import Button from '../common/Button';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const THUMBNAIL_SIZE = (SCREEN_WIDTH - 48) / 3;

const EventGallery = ({
  images,
  onAddImages,
  editable = false,
  style
}) => {
  const { colors, typography } = useTheme();
  const [selectedImageIndex, setSelectedImageIndex] = useState(null);
  const [showGalleryModal, setShowGalleryModal] = useState(false);

  const handleImagePress = (index) => {
    setSelectedImageIndex(index);
    setShowGalleryModal(true);
  };

  const handlePrevImage = () => {
    setSelectedImageIndex((prev) =>
      prev > 0 ? prev - 1 : images.length - 1
    );
  };

  const handleNextImage = () => {
    setSelectedImageIndex((prev) =>
      prev < images.length - 1 ? prev + 1 : 0
    );
  };

  const renderThumbnail = ({ item: image, index }) => (
    <TouchableOpacity
      style={styles.thumbnailContainer}
      onPress={() => handleImagePress(index)}
      activeOpacity={0.8}
    >
      <Image
        source={{ uri: image.url }}
        style={styles.thumbnail}
      />
      {editable && (
        <TouchableOpacity
          style={[
            styles.deleteButton,
            { backgroundColor: colors.error }
          ]}
          onPress={() => onAddImages(
            images.filter((_, i) => i !== index)
          )}
        >
          <Icon
            name="trash"
            size={16}
            color={colors.surface}
          />
        </TouchableOpacity>
      )}
    </TouchableOpacity>
  );

  const renderAddButton = () => {
    if (!editable || images.length >= 9) return null;

    return (
      <TouchableOpacity
        style={[
          styles.addButton,
          {
            backgroundColor: colors.surface,
            borderColor: colors.border
          }
        ]}
        onPress={() => onAddImages([...images])}
      >
        <Icon
          name="plus"
          size={24}
          color={colors.primary}
        />
        <Text
          style={[
            styles.addButtonText,
            {
              color: colors.primary,
              ...typography.button
            }
          ]}
        >
          Add Photo
        </Text>
      </TouchableOpacity>
    );
  };

  const renderGalleryModal = () => (
    <Modal
      visible={showGalleryModal}
      transparent
      animationType="fade"
      onRequestClose={() => setShowGalleryModal(false)}
    >
      <View
        style={[
          styles.modalContainer,
          { backgroundColor: colors.background }
        ]}
      >
        <View style={styles.modalHeader}>
          <TouchableOpacity
            onPress={() => setShowGalleryModal(false)}
            hitSlop={{ top: 10, right: 10, bottom: 10, left: 10 }}
          >
            <Icon
              name="close"
              size={24}
              color={colors.text}
            />
          </TouchableOpacity>
          <Text
            style={[
              styles.imageCounter,
              { color: colors.text }
            ]}
          >
            {selectedImageIndex + 1} / {images.length}
          </Text>
        </View>

        <View style={styles.modalContent}>
          <TouchableOpacity
            style={[
              styles.navButton,
              styles.prevButton,
              { backgroundColor: colors.surface }
            ]}
            onPress={handlePrevImage}
          >
            <Icon
              name="chevron-left"
              size={24}
              color={colors.text}
            />
          </TouchableOpacity>

          <Image
            source={{ uri: images[selectedImageIndex]?.url }}
            style={styles.fullImage}
            resizeMode="contain"
          />

          <TouchableOpacity
            style={[
              styles.navButton,
              styles.nextButton,
              { backgroundColor: colors.surface }
            ]}
            onPress={handleNextImage}
          >
            <Icon
              name="chevron-right"
              size={24}
              color={colors.text}
            />
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );

  if (images.length === 0 && !editable) {
    return null;
  }

  return (
    <View style={[styles.container, style]}>
      <FlatList
        data={images}
        renderItem={renderThumbnail}
        keyExtractor={(item, index) => `${item.url}-${index}`}
        numColumns={3}
        columnWrapperStyle={styles.row}
        scrollEnabled={false}
        ListFooterComponent={renderAddButton}
      />
      {renderGalleryModal()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  row: {
    gap: 8,
    marginBottom: 8,
  },
  thumbnailContainer: {
    width: THUMBNAIL_SIZE,
    height: THUMBNAIL_SIZE,
    borderRadius: 8,
    overflow: 'hidden',
  },
  thumbnail: {
    width: '100%',
    height: '100%',
  },
  deleteButton: {
    position: 'absolute',
    top: 8,
    right: 8,
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  addButton: {
    width: THUMBNAIL_SIZE,
    height: THUMBNAIL_SIZE,
    borderRadius: 8,
    borderWidth: 1,
    borderStyle: 'dashed',
    alignItems: 'center',
    justifyContent: 'center',
  },
  addButtonText: {
    marginTop: 4,
    fontSize: 12,
    fontWeight: '500',
  },
  modalContainer: {
    flex: 1,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    paddingTop: Platform.OS === 'ios' ? 60 : 16,
  },
  imageCounter: {
    fontSize: 16,
    fontWeight: '500',
  },
  modalContent: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  fullImage: {
    width: '100%',
    height: '100%',
  },
  navButton: {
    position: 'absolute',
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.25,
        shadowRadius: 4,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  prevButton: {
    left: 16,
  },
  nextButton: {
    right: 16,
  },
});

export default EventGallery;
