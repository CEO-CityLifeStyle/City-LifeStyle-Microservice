# Offline Support Documentation

## Overview
The offline support system enables the application to function without an internet connection, providing data synchronization, conflict resolution, and background updates when connectivity is restored.

## Current Implementation

### 1. Service Worker

```javascript
// frontend/src/serviceWorker.js
const CACHE_NAME = 'city-lifestyle-cache-v1';
const DYNAMIC_CACHE = 'city-lifestyle-dynamic-v1';

const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/static/js/main.js',
  '/static/css/main.css',
  '/static/media/logo.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS);
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys
          .filter(key => key !== CACHE_NAME && key !== DYNAMIC_CACHE)
          .map(key => caches.delete(key))
      );
    })
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request).then((fetchResponse) => {
        return caches.open(DYNAMIC_CACHE).then((cache) => {
          cache.put(event.request.url, fetchResponse.clone());
          return fetchResponse;
        });
      });
    }).catch(() => {
      if (event.request.url.indexOf('/api/') === -1) {
        return caches.match('/offline.html');
      }
    })
  );
});

self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-pending-actions') {
    event.waitUntil(syncPendingActions());
  }
});
```

### 2. IndexedDB Service

```javascript
// frontend/src/services/indexedDBService.js
class IndexedDBService {
  constructor() {
    this.dbName = 'CityLifestyleDB';
    this.version = 1;
    this.db = null;
  }

  async initialize() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.version);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve(this.db);
      };

      request.onupgradeneeded = (event) => {
        const db = event.target.result;

        // Create object stores
        db.createObjectStore('places', { keyPath: 'id' });
        db.createObjectStore('events', { keyPath: 'id' });
        db.createObjectStore('profiles', { keyPath: 'id' });
        db.createObjectStore('pendingActions', { keyPath: 'id', autoIncrement: true });
      };
    });
  }

  async get(storeName, key) {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(storeName, 'readonly');
      const store = transaction.objectStore(storeName);
      const request = store.get(key);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
    });
  }

  async getAll(storeName) {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(storeName, 'readonly');
      const store = transaction.objectStore(storeName);
      const request = store.getAll();

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
    });
  }

  async put(storeName, item) {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(storeName, 'readwrite');
      const store = transaction.objectStore(storeName);
      const request = store.put(item);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
    });
  }

  async delete(storeName, key) {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(storeName, 'readwrite');
      const store = transaction.objectStore(storeName);
      const request = store.delete(key);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
    });
  }
}
```

### 3. Offline Actions Queue

```javascript
// frontend/src/services/offlineQueueService.js
class OfflineQueueService {
  constructor(indexedDB) {
    this.indexedDB = indexedDB;
  }

  async queueAction(action) {
    const timestamp = new Date().toISOString();
    
    await this.indexedDB.put('pendingActions', {
      ...action,
      timestamp,
      status: 'pending'
    });

    // Register for background sync if available
    if ('serviceWorker' in navigator && 'SyncManager' in window) {
      const registration = await navigator.serviceWorker.ready;
      await registration.sync.register('sync-pending-actions');
    }
  }

  async processPendingActions() {
    const actions = await this.indexedDB.getAll('pendingActions');
    const sortedActions = actions.sort((a, b) => 
      new Date(a.timestamp) - new Date(b.timestamp)
    );

    for (const action of sortedActions) {
      try {
        await this.processAction(action);
        await this.indexedDB.delete('pendingActions', action.id);
      } catch (error) {
        console.error('Failed to process action:', error);
        
        // Update retry count and status
        await this.indexedDB.put('pendingActions', {
          ...action,
          retryCount: (action.retryCount || 0) + 1,
          lastError: error.message,
          status: 'failed'
        });
      }
    }
  }

  async processAction(action) {
    switch (action.type) {
      case 'CREATE':
        return api.post(action.endpoint, action.data);
      case 'UPDATE':
        return api.put(`${action.endpoint}/${action.id}`, action.data);
      case 'DELETE':
        return api.delete(`${action.endpoint}/${action.id}`);
      default:
        throw new Error(`Unknown action type: ${action.type}`);
    }
  }
}
```

### 4. Offline Hook

```javascript
// frontend/src/hooks/useOffline.js
const useOffline = () => {
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [isSyncing, setIsSyncing] = useState(false);
  const [lastSynced, setLastSynced] = useState(null);
  
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  useEffect(() => {
    if (isOnline) {
      syncData();
    }
  }, [isOnline]);

  const syncData = async () => {
    if (isSyncing) return;

    try {
      setIsSyncing(true);
      await offlineQueueService.processPendingActions();
      setLastSynced(new Date());
    } finally {
      setIsSyncing(false);
    }
  };

  return {
    isOnline,
    isSyncing,
    lastSynced,
    syncData
  };
};
```

## Remaining Implementation

### 1. Enhanced Conflict Resolution

```javascript
// frontend/src/services/conflictResolutionService.js
class ConflictResolutionService {
  async resolveConflict(localData, serverData) {
    // Compare timestamps
    if (new Date(localData.updatedAt) > new Date(serverData.updatedAt)) {
      return localData;
    }

    // Compare version numbers
    if (localData.version > serverData.version) {
      return localData;
    }

    // Field-level merge for complex objects
    return this.mergeData(localData, serverData);
  }

  private async mergeData(local, server) {
    const merged = { ...server };

    // Merge arrays using unique identifiers
    for (const key in local) {
      if (Array.isArray(local[key])) {
        merged[key] = this.mergeArrays(local[key], server[key]);
      }
    }

    return merged;
  }

  private mergeArrays(localArray, serverArray) {
    const merged = [...serverArray];
    const serverIds = new Set(serverArray.map(item => item.id));

    // Add local items that don't exist on server
    for (const localItem of localArray) {
      if (!serverIds.has(localItem.id)) {
        merged.push(localItem);
      }
    }

    return merged;
  }
}
```

### 2. Background Sync

```javascript
// frontend/src/services/backgroundSyncService.js
class BackgroundSyncService {
  constructor() {
    this.syncInterval = 5 * 60 * 1000; // 5 minutes
  }

  async initialize() {
    if ('serviceWorker' in navigator && 'SyncManager' in window) {
      const registration = await navigator.serviceWorker.ready;
      
      // Register periodic sync if available
      if ('periodicSync' in registration) {
        try {
          await registration.periodicSync.register('sync-data', {
            minInterval: this.syncInterval
          });
        } catch (error) {
          console.error('Periodic sync could not be registered:', error);
        }
      }
    }
  }

  async syncData() {
    const stores = ['places', 'events', 'profiles'];
    
    for (const store of stores) {
      await this.syncStore(store);
    }
  }

  private async syncStore(storeName) {
    const localData = await indexedDB.getAll(storeName);
    const serverData = await api.get(`/${storeName}`).then(res => res.data);
    
    const conflicts = this.findConflicts(localData, serverData);
    
    for (const conflict of conflicts) {
      const resolution = await conflictResolutionService.resolveConflict(
        conflict.local,
        conflict.server
      );
      
      await this.applyResolution(storeName, resolution);
    }
  }
}
```

### 3. Progressive Loading

```javascript
// frontend/src/services/progressiveLoadingService.js
class ProgressiveLoadingService {
  constructor(indexedDB) {
    this.indexedDB = indexedDB;
    this.pageSize = 20;
  }

  async loadData(storeName, page = 1) {
    // Try loading from IndexedDB first
    const localData = await this.loadFromIndexedDB(storeName, page);
    if (localData.length > 0) {
      return localData;
    }

    // Fetch from server if not in IndexedDB
    const serverData = await this.loadFromServer(storeName, page);
    
    // Cache the data
    await this.cacheData(storeName, serverData);
    
    return serverData;
  }

  private async loadFromIndexedDB(storeName, page) {
    const store = await this.indexedDB.getStore(storeName);
    return store.getAll(
      IDBKeyRange.bound(
        (page - 1) * this.pageSize,
        page * this.pageSize
      )
    );
  }

  private async loadFromServer(storeName, page) {
    return api.get(`/${storeName}`, {
      params: {
        page,
        pageSize: this.pageSize
      }
    }).then(res => res.data);
  }

  private async cacheData(storeName, data) {
    const store = await this.indexedDB.getStore(storeName);
    await Promise.all(
      data.map(item => store.put(item))
    );
  }
}
```

## Implementation Timeline

### Week 1: Enhanced Sync
- Implement conflict resolution
- Add field-level merging
- Create sync status tracking
- Add retry mechanism

### Week 2: Background Processing
- Set up background sync
- Add periodic sync
- Implement progressive loading
- Create offline indicators

## Success Metrics
- Offline availability > 98%
- Sync success rate > 95%
- Conflict resolution success > 99%
- Data consistency > 99.9%

## Offline Support Checklist
- [x] Basic offline storage
- [x] Service worker caching
- [x] Offline queue
- [x] Basic sync
- [ ] Enhanced conflict resolution
- [ ] Background sync
- [ ] Progressive loading
- [ ] Offline analytics
- [ ] Sync status indicators
- [ ] Error recovery
