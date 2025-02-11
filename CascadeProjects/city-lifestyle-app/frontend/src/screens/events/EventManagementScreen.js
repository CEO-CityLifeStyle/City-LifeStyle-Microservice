import React, { useState, useEffect } from 'react';
import {
  View,
  ScrollView,
  StyleSheet,
  Alert,
  ActivityIndicator
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchEventDetail,
  updateEvent,
  cancelEvent,
  selectEventDetail,
  selectEventLoading,
  selectEventError
} from '../../store/slices/eventsSlice';
import {
  fetchEventRSVPs,
  updateRSVP,
  selectEventRSVPs,
  selectRSVPsLoading
} from '../../store/slices/rsvpSlice';
import EventStats from '../../components/events/EventStats';
import AttendeeManagement from '../../components/events/AttendeeManagement';
import WaitlistManagement from '../../components/events/WaitlistManagement';
import Button from '../../components/common/Button';
import ErrorView from '../../components/common/ErrorView';
import { useTheme } from '../../hooks/useTheme';
import { SCREEN_PADDING } from '../../constants/layout';

const EventManagementScreen = () => {
  const route = useRoute();
  const navigation = useNavigation();
  const dispatch = useDispatch();
  const { colors } = useTheme();

  // Get eventId from route params
  const { eventId } = route.params;

  // Redux
  const event = useSelector(state => selectEventDetail(state, eventId));
  const rsvps = useSelector(state => selectEventRSVPs(state, eventId));
  const loading = useSelector(selectEventLoading);
  const rsvpsLoading = useSelector(selectRSVPsLoading);
  const error = useSelector(selectEventError);

  // State
  const [selectedTab, setSelectedTab] = useState('confirmed'); // 'confirmed' or 'waitlist'

  // Effects
  useEffect(() => {
    loadEventData();
  }, [eventId]);

  // Handlers
  const loadEventData = async () => {
    await Promise.all([
      dispatch(fetchEventDetail(eventId)),
      dispatch(fetchEventRSVPs(eventId))
    ]);
  };

  const handleEditPress = () => {
    navigation.navigate('CreateEditEvent', { eventId });
  };

  const handlePublishPress = async () => {
    try {
      await dispatch(updateEvent({
        eventId,
        updates: { status: 'published' }
      })).unwrap();
      Alert.alert('Success', 'Event has been published');
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  };

  const handleCancelPress = () => {
    Alert.alert(
      'Cancel Event',
      'Are you sure you want to cancel this event? This action cannot be undone.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Yes',
          style: 'destructive',
          onPress: async () => {
            try {
              await dispatch(cancelEvent(eventId)).unwrap();
              Alert.alert('Success', 'Event has been cancelled');
            } catch (error) {
              Alert.alert('Error', error.message);
            }
          }
        }
      ]
    );
  };

  const handleApproveRSVP = async (rsvpId) => {
    try {
      await dispatch(updateRSVP({
        rsvpId,
        updates: { status: 'confirmed' }
      })).unwrap();
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  };

  const handleRejectRSVP = async (rsvpId) => {
    try {
      await dispatch(updateRSVP({
        rsvpId,
        updates: { status: 'declined' }
      })).unwrap();
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  };

  if (error) {
    return (
      <ErrorView
        error={error}
        onRetry={loadEventData}
      />
    );
  }

  if (loading || !event) {
    return (
      <View style={[styles.container, styles.centered]}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  const confirmedRSVPs = rsvps.filter(rsvp => rsvp.status === 'confirmed');
  const waitlistedRSVPs = rsvps.filter(rsvp => rsvp.status === 'waitlisted');

  return (
    <ScrollView
      style={[styles.container, { backgroundColor: colors.background }]}
      contentContainerStyle={styles.content}
      showsVerticalScrollIndicator={false}
    >
      {/* Event Status Actions */}
      <View style={styles.actions}>
        {event.status === 'draft' && (
          <Button
            title="Publish Event"
            onPress={handlePublishPress}
            style={styles.actionButton}
          />
        )}
        <Button
          title="Edit Event"
          onPress={handleEditPress}
          variant="outlined"
          style={styles.actionButton}
        />
        {event.status === 'published' && (
          <Button
            title="Cancel Event"
            onPress={handleCancelPress}
            variant="danger"
            style={styles.actionButton}
          />
        )}
      </View>

      {/* Event Statistics */}
      <EventStats
        confirmedCount={confirmedRSVPs.length}
        waitlistCount={waitlistedRSVPs.length}
        capacity={event.capacity}
        views={event.metadata.views}
        shares={event.metadata.shares}
        style={styles.stats}
      />

      {/* Attendee Management */}
      <View style={styles.tabs}>
        <Button
          title="Confirmed"
          variant={selectedTab === 'confirmed' ? 'filled' : 'outlined'}
          onPress={() => setSelectedTab('confirmed')}
          style={styles.tab}
        />
        <Button
          title="Waitlist"
          variant={selectedTab === 'waitlist' ? 'filled' : 'outlined'}
          onPress={() => setSelectedTab('waitlist')}
          style={styles.tab}
        />
      </View>

      {selectedTab === 'confirmed' ? (
        <AttendeeManagement
          rsvps={confirmedRSVPs}
          onApprove={handleApproveRSVP}
          onReject={handleRejectRSVP}
          loading={rsvpsLoading}
          style={styles.management}
        />
      ) : (
        <WaitlistManagement
          rsvps={waitlistedRSVPs}
          onApprove={handleApproveRSVP}
          onReject={handleRejectRSVP}
          loading={rsvpsLoading}
          style={styles.management}
        />
      )}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  centered: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    padding: SCREEN_PADDING,
    gap: 24,
  },
  actions: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 24,
  },
  actionButton: {
    flex: 1,
  },
  stats: {
    marginBottom: 24,
  },
  tabs: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 16,
  },
  tab: {
    flex: 1,
  },
  management: {
    flex: 1,
  },
});

export default EventManagementScreen;
