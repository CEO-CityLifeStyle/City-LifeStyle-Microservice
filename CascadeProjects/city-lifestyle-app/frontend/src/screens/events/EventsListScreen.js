import React, { useState, useEffect } from 'react';
import {
  View,
  StyleSheet,
  FlatList,
  RefreshControl,
  ActivityIndicator
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchEvents,
  selectEvents,
  selectEventsLoading,
  selectEventsError
} from '../../store/slices/eventsSlice';
import EventCard from '../../components/events/EventCard';
import EventFilters from '../../components/events/EventFilters';
import EventSearchBar from '../../components/events/EventSearchBar';
import ErrorView from '../../components/common/ErrorView';
import { useLocation } from '../../hooks/useLocation';
import { useTheme } from '../../hooks/useTheme';
import { SCREEN_PADDING } from '../../constants/layout';

const EventsListScreen = () => {
  const navigation = useNavigation();
  const dispatch = useDispatch();
  const { colors } = useTheme();
  const { location } = useLocation();

  // State
  const [refreshing, setRefreshing] = useState(false);
  const [viewType, setViewType] = useState('grid'); // 'grid' or 'list'
  const [filters, setFilters] = useState({
    category: null,
    date: null,
    distance: 10000, // 10km
    sort: 'date' // 'date', 'distance', 'popularity'
  });
  const [searchQuery, setSearchQuery] = useState('');

  // Redux
  const events = useSelector(selectEvents);
  const loading = useSelector(selectEventsLoading);
  const error = useSelector(selectEventsError);

  // Effects
  useEffect(() => {
    loadEvents();
  }, [location, filters]);

  // Handlers
  const loadEvents = async () => {
    if (location) {
      dispatch(fetchEvents({
        location,
        filters,
        search: searchQuery
      }));
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadEvents();
    setRefreshing(false);
  };

  const handleEventPress = (event) => {
    navigation.navigate('EventDetail', { eventId: event.id });
  };

  const handleFilterChange = (newFilters) => {
    setFilters(prev => ({ ...prev, ...newFilters }));
  };

  const handleSearch = (query) => {
    setSearchQuery(query);
    dispatch(fetchEvents({
      location,
      filters,
      search: query
    }));
  };

  const handleViewTypeToggle = () => {
    setViewType(prev => prev === 'grid' ? 'list' : 'grid');
  };

  // Render helpers
  const renderEvent = ({ item }) => (
    <EventCard
      event={item}
      onPress={() => handleEventPress(item)}
      viewType={viewType}
    />
  );

  const renderHeader = () => (
    <View style={styles.header}>
      <EventSearchBar
        value={searchQuery}
        onChangeText={handleSearch}
        style={styles.searchBar}
      />
      <EventFilters
        filters={filters}
        onFilterChange={handleFilterChange}
        onViewTypeChange={handleViewTypeToggle}
        viewType={viewType}
      />
    </View>
  );

  if (error) {
    return (
      <ErrorView
        error={error}
        onRetry={loadEvents}
      />
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <FlatList
        data={events}
        renderItem={renderEvent}
        keyExtractor={item => item.id}
        numColumns={viewType === 'grid' ? 2 : 1}
        key={viewType} // Force re-render on view type change
        contentContainerStyle={styles.list}
        ListHeaderComponent={renderHeader}
        ListEmptyComponent={
          loading ? (
            <ActivityIndicator
              size="large"
              color={colors.primary}
              style={styles.loader}
            />
          ) : (
            <View style={styles.emptyState}>
              <Text style={[styles.emptyText, { color: colors.text }]}>
                No events found
              </Text>
            </View>
          )
        }
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            colors={[colors.primary]}
          />
        }
        onEndReached={() => {
          // Implement pagination if needed
        }}
        onEndReachedThreshold={0.5}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    padding: SCREEN_PADDING,
    gap: 12,
  },
  searchBar: {
    marginBottom: 12,
  },
  list: {
    padding: SCREEN_PADDING,
  },
  loader: {
    marginTop: 40,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 40,
  },
  emptyText: {
    fontSize: 16,
    textAlign: 'center',
  },
});

export default EventsListScreen;
