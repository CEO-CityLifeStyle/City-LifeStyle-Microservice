import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Modal,
  ScrollView,
  Platform
} from 'react-native';
import { useTheme } from '../../hooks/useTheme';
import Icon from '../common/Icon';
import Button from '../common/Button';
import Slider from '../common/Slider';
import { formatDate } from '../../utils/dateUtils';

const SORT_OPTIONS = [
  { id: 'date', label: 'Date', icon: 'calendar' },
  { id: 'distance', label: 'Distance', icon: 'location' },
  { id: 'popularity', label: 'Popularity', icon: 'trending' }
];

const EventFilters = ({
  filters,
  onFilterChange,
  onViewTypeChange,
  viewType,
  style
}) => {
  const { colors, typography } = useTheme();
  const [showFiltersModal, setShowFiltersModal] = useState(false);
  const [tempFilters, setTempFilters] = useState(filters);

  const handleSortPress = (sortOption) => {
    setTempFilters(prev => ({
      ...prev,
      sort: sortOption
    }));
  };

  const handleDistanceChange = (distance) => {
    setTempFilters(prev => ({
      ...prev,
      distance
    }));
  };

  const handleDateChange = (date) => {
    setTempFilters(prev => ({
      ...prev,
      date
    }));
  };

  const handleApplyFilters = () => {
    onFilterChange(tempFilters);
    setShowFiltersModal(false);
  };

  const handleResetFilters = () => {
    const defaultFilters = {
      category: null,
      date: null,
      distance: 10000,
      sort: 'date'
    };
    setTempFilters(defaultFilters);
    onFilterChange(defaultFilters);
    setShowFiltersModal(false);
  };

  const renderFilterButton = () => (
    <TouchableOpacity
      style={[
        styles.filterButton,
        {
          backgroundColor: colors.surface,
          borderColor: colors.border
        }
      ]}
      onPress={() => setShowFiltersModal(true)}
    >
      <Icon
        name="filter"
        size={20}
        color={colors.text}
      />
      <Text
        style={[
          styles.filterButtonText,
          { color: colors.text }
        ]}
      >
        Filters
      </Text>
      {Object.values(filters).some(Boolean) && (
        <View
          style={[
            styles.filterBadge,
            { backgroundColor: colors.primary }
          ]}
        />
      )}
    </TouchableOpacity>
  );

  const renderViewTypeButton = () => (
    <TouchableOpacity
      style={[
        styles.viewTypeButton,
        {
          backgroundColor: colors.surface,
          borderColor: colors.border
        }
      ]}
      onPress={() => onViewTypeChange(viewType === 'grid' ? 'list' : 'grid')}
    >
      <Icon
        name={viewType === 'grid' ? 'grid' : 'list'}
        size={20}
        color={colors.text}
      />
    </TouchableOpacity>
  );

  const renderFiltersModal = () => (
    <Modal
      visible={showFiltersModal}
      transparent
      animationType="slide"
      onRequestClose={() => setShowFiltersModal(false)}
    >
      <View style={styles.modalOverlay}>
        <View
          style={[
            styles.modalContent,
            { backgroundColor: colors.background }
          ]}
        >
          <View
            style={[
              styles.modalHeader,
              { borderBottomColor: colors.border }
            ]}
          >
            <Text
              style={[
                styles.modalTitle,
                { color: colors.text }
              ]}
            >
              Filters
            </Text>
            <TouchableOpacity
              onPress={() => setShowFiltersModal(false)}
            >
              <Icon
                name="close"
                size={24}
                color={colors.text}
              />
            </TouchableOpacity>
          </View>

          <ScrollView
            style={styles.modalBody}
            showsVerticalScrollIndicator={false}
          >
            {/* Sort Options */}
            <View style={styles.section}>
              <Text
                style={[
                  styles.sectionTitle,
                  { color: colors.text }
                ]}
              >
                Sort By
              </Text>
              <View style={styles.sortOptions}>
                {SORT_OPTIONS.map(option => (
                  <TouchableOpacity
                    key={option.id}
                    style={[
                      styles.sortOption,
                      {
                        backgroundColor:
                          tempFilters.sort === option.id
                            ? colors.primaryLight
                            : colors.surface,
                        borderColor:
                          tempFilters.sort === option.id
                            ? colors.primary
                            : colors.border
                      }
                    ]}
                    onPress={() => handleSortPress(option.id)}
                  >
                    <Icon
                      name={option.icon}
                      size={20}
                      color={
                        tempFilters.sort === option.id
                          ? colors.primary
                          : colors.text
                      }
                    />
                    <Text
                      style={[
                        styles.sortOptionText,
                        {
                          color:
                            tempFilters.sort === option.id
                              ? colors.primary
                              : colors.text
                        }
                      ]}
                    >
                      {option.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Distance Filter */}
            <View style={styles.section}>
              <Text
                style={[
                  styles.sectionTitle,
                  { color: colors.text }
                ]}
              >
                Distance
              </Text>
              <Slider
                value={tempFilters.distance}
                onValueChange={handleDistanceChange}
                minimumValue={1000}
                maximumValue={50000}
                step={1000}
                formatLabel={(value) => `${value / 1000}km`}
              />
            </View>

            {/* Date Filter */}
            <View style={styles.section}>
              <Text
                style={[
                  styles.sectionTitle,
                  { color: colors.text }
                ]}
              >
                Date
              </Text>
              <View style={styles.dateButtons}>
                <Button
                  title="Today"
                  onPress={() => handleDateChange('today')}
                  variant={
                    tempFilters.date === 'today'
                      ? 'filled'
                      : 'outlined'
                  }
                  style={styles.dateButton}
                />
                <Button
                  title="Tomorrow"
                  onPress={() => handleDateChange('tomorrow')}
                  variant={
                    tempFilters.date === 'tomorrow'
                      ? 'filled'
                      : 'outlined'
                  }
                  style={styles.dateButton}
                />
                <Button
                  title="This Week"
                  onPress={() => handleDateChange('week')}
                  variant={
                    tempFilters.date === 'week'
                      ? 'filled'
                      : 'outlined'
                  }
                  style={styles.dateButton}
                />
              </View>
            </View>
          </ScrollView>

          <View
            style={[
              styles.modalFooter,
              { borderTopColor: colors.border }
            ]}
          >
            <Button
              title="Reset"
              onPress={handleResetFilters}
              variant="outlined"
              style={styles.footerButton}
            />
            <Button
              title="Apply"
              onPress={handleApplyFilters}
              style={styles.footerButton}
            />
          </View>
        </View>
      </View>
    </Modal>
  );

  return (
    <View style={[styles.container, style]}>
      {renderFilterButton()}
      {renderViewTypeButton()}
      {renderFiltersModal()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    gap: 12,
  },
  filterButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    gap: 8,
  },
  filterButtonText: {
    fontSize: 16,
  },
  filterBadge: {
    width: 8,
    height: 8,
    borderRadius: 4,
    position: 'absolute',
    top: 8,
    right: 8,
  },
  viewTypeButton: {
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    aspectRatio: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  modalContent: {
    flex: 1,
    marginTop: 60,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: '600',
  },
  modalBody: {
    flex: 1,
    padding: 16,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 16,
  },
  sortOptions: {
    flexDirection: 'row',
    gap: 12,
  },
  sortOption: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    gap: 8,
  },
  sortOptionText: {
    fontSize: 14,
    fontWeight: '500',
  },
  dateButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  dateButton: {
    flex: 1,
  },
  modalFooter: {
    flexDirection: 'row',
    gap: 12,
    padding: 16,
    borderTopWidth: 1,
    paddingBottom: Platform.OS === 'ios' ? 40 : 16,
  },
  footerButton: {
    flex: 1,
  },
});

export default EventFilters;
