import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity
} from 'react-native';
import { useTheme } from '../../hooks/useTheme';
import Icon from '../common/Icon';

const CATEGORIES = [
  {
    id: 'music',
    name: 'Music',
    icon: 'music'
  },
  {
    id: 'sports',
    name: 'Sports',
    icon: 'sports'
  },
  {
    id: 'art',
    name: 'Art',
    icon: 'art'
  },
  {
    id: 'food',
    name: 'Food',
    icon: 'food'
  },
  {
    id: 'education',
    name: 'Education',
    icon: 'education'
  },
  {
    id: 'technology',
    name: 'Technology',
    icon: 'technology'
  },
  {
    id: 'business',
    name: 'Business',
    icon: 'business'
  },
  {
    id: 'social',
    name: 'Social',
    icon: 'social'
  },
  {
    id: 'health',
    name: 'Health',
    icon: 'health'
  },
  {
    id: 'other',
    name: 'Other',
    icon: 'more'
  }
];

const CategoryPicker = ({
  value,
  onChange,
  error,
  style
}) => {
  const { colors, typography } = useTheme();

  const renderCategory = (category) => {
    const isSelected = value === category.id;

    return (
      <TouchableOpacity
        key={category.id}
        style={[
          styles.category,
          {
            backgroundColor: isSelected
              ? colors.primaryLight
              : colors.surface,
            borderColor: isSelected
              ? colors.primary
              : colors.border
          }
        ]}
        onPress={() => onChange(category.id)}
        activeOpacity={0.7}
      >
        <Icon
          name={category.icon}
          size={24}
          color={isSelected ? colors.primary : colors.text}
        />
        <Text
          style={[
            styles.categoryName,
            {
              color: isSelected ? colors.primary : colors.text,
              ...typography.caption
            }
          ]}
        >
          {category.name}
        </Text>
      </TouchableOpacity>
    );
  };

  return (
    <View style={[styles.container, style]}>
      <Text
        style={[
          styles.label,
          { color: error ? colors.error : colors.text }
        ]}
      >
        Category
      </Text>

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.categoriesContainer}
      >
        {CATEGORIES.map(renderCategory)}
      </ScrollView>

      {error && (
        <Text style={[styles.error, { color: colors.error }]}>
          {error}
        </Text>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  label: {
    fontSize: 16,
    fontWeight: '500',
    marginBottom: 8,
  },
  categoriesContainer: {
    paddingVertical: 4,
    gap: 12,
  },
  category: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    minWidth: 80,
  },
  categoryName: {
    marginTop: 4,
    textAlign: 'center',
  },
  error: {
    fontSize: 14,
    marginTop: 4,
  },
});

export default CategoryPicker;
