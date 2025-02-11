import React, { useState, useEffect } from 'react';
import {
  View,
  ScrollView,
  StyleSheet,
  Share,
  Alert,
  ActivityIndicator,
  Dimensions
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchEventDetail,
  selectEventDetail,
  selectEventLoading,
  selectEventError
} from '../../store/slices/eventsSlice';
import {
  createRSVP,
  updateRSVP,
  cancelRSVP,
  selectRSVPStatus
} from '../../store/slices/rsvpSlice';
import ImageGallery from '../../components/events/ImageGallery';
import EventInfo from '../../components/events/EventInfo';
import RSVPButton from '../../components/events/RSVPButton';
import AttendeesList from '../../components/events/AttendeesList';
import EventMap from '../../components/events/EventMap';
import ErrorView from '../../components/common/ErrorView';
import { useTheme } from '../../hooks/useTheme';
import { useAuth } from '../../hooks/useAuth';
import { formatDate, formatTime } from '../../utils/dateUtils';
import { SCREEN_PADDING } from '../../constants/layout';

const { width } = Dimensions.get('window');

const EventDetailScreen = () => {
  const route = useRoute();
  const navigation = useNavigation();
  const dispatch = useDispatch();
  const { colors } = useTheme();
  const { user } = useAuth();

  // Get eventId from route params
  const { eventId } = route.params;

  // State
  const [ticketCount, setTicketCount] = useState(1);
  const [showAllDescription, setShowAllDescription] = useState(false);
  const [selectedImageIndex, setSelectedImageIndex] = useState(0);

  // Redux
  const event = useSelector(state => selectEventDetail(state, eventId));
  const loading = useSelector(selectEventLoading);
  const error = useSelector(selectEventError);
  const rsvpStatus = useSelector(state => selectRSVPStatus(state, eventId));

  // Effects
  useEffect(() => {
    loadEventDetail();
  }, [eventId]);

  // Handlers
  const loadEventDetail = () => {
    dispatch(fetchEventDetail(eventId));
  };

  const handleRSVP = async () => {
    if (!user) {
      navigation.navigate('Auth', {
        screen: 'Login',
        params: { returnTo: 'EventDetail', eventId }
      });
      return;
    }

    try {
      if (!rsvpStatus) {
        await dispatch(createRSVP({
          eventId,
          ticketCount,
          notes: ''
        })).unwrap();
        Alert.alert('Success', 'Your RSVP has been confirmed!');
      } else if (rsvpStatus === 'confirmed' || rsvpStatus === 'waitlisted') {
        Alert.alert(
          'Cancel RSVP',
          'Are you sure you want to cancel your RSVP?',
          [
            { text: 'No', style: 'cancel' },
            {
              text: 'Yes',
              style: 'destructive',
              onPress: async () => {
                await dispatch(cancelRSVP(eventId)).unwrap();
                Alert.alert('Success', 'Your RSVP has been cancelled.');
              }
            }
          ]
        );
      }
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  };

  const handleShare = async () => {
    try {
      await Share.share({
        message: `Check out ${event.title} on City Lifestyle!\n${event.shareUrl}`,
        url: event.shareUrl
      });
    } catch (error) {
      console.error('Error sharing event:', error);
    }
  };

  const handlePlacePress = () => {
    navigation.navigate('PlaceDetail', { placeId: event.placeId });
  };

  const handleOrganizerPress = () => {
    navigation.navigate('Profile', { userId: event.organizerId });
  };

  const handleTicketCountChange = (count) => {
    setTicketCount(count);
  };

  if (error) {
    return (
      <ErrorView
        error={error}
        onRetry={loadEventDetail}
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

  return (
    <ScrollView
      style={[styles.container, { backgroundColor: colors.background }]}
      showsVerticalScrollIndicator={false}
    >
      <ImageGallery
        images={event.images}
        selectedIndex={selectedImageIndex}
        onIndexChange={setSelectedImageIndex}
        style={styles.gallery}
      />

      <View style={styles.content}>
        <EventInfo
          event={event}
          showAllDescription={showAllDescription}
          onToggleDescription={() => setShowAllDescription(!showAllDescription)}
          onPlacePress={handlePlacePress}
          onOrganizerPress={handleOrganizerPress}
          onShare={handleShare}
          style={styles.info}
        />

        <RSVPButton
          status={rsvpStatus}
          ticketCount={ticketCount}
          onTicketCountChange={handleTicketCountChange}
          onPress={handleRSVP}
          disabled={event.status !== 'published'}
          style={styles.rsvpButton}
        />

        <EventMap
          location={event.location}
          placeName={event.place.name}
          onPress={handlePlacePress}
          style={styles.map}
        />

        <AttendeesList
          eventId={eventId}
          attendees={event.attendees}
          style={styles.attendees}
        />
      </View>
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
  gallery: {
    width: width,
    height: width * 0.75,
  },
  content: {
    padding: SCREEN_PADDING,
    gap: 24,
  },
  info: {
    marginBottom: 16,
  },
  rsvpButton: {
    marginVertical: 16,
  },
  map: {
    height: 200,
    borderRadius: 12,
    marginBottom: 24,
  },
  attendees: {
    marginBottom: 24,
  },
});

export default EventDetailScreen;
