pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: service

    readonly property int maxPopups: 1
    readonly property int maxHistory: 40

    property bool doNotDisturb: false

    ListModel { id: popupModel }
    ListModel { id: historyModel }

    property alias popups: popupModel
    property alias history: historyModel

    property var liveRefs: ({})
    property var popupTimers: ({})

    component PopupTimer: Timer {
        required property string entryKey
        repeat: false
        running: true
        onTriggered: service.expirePopup(entryKey)
    }

    Component {
        id: timerComponent
        PopupTimer {}
    }

    function durationFor(urgency, expireTimeout) {
        if (urgency === NotificationUrgency.Critical)
            return 0

        const requested = Number(expireTimeout || 0)
        let milliseconds = 0
        if (isFinite(requested) && requested > 0)
            milliseconds = requested <= 300 ? requested * 1000 : requested

        const fallback = urgency === NotificationUrgency.Low ? 4000 : 6000
        if (milliseconds <= 0)
            return fallback

        return Math.min(15000, Math.max(3000, Math.round(milliseconds)))
    }

    function makeSnapshot(notification, entryKey, timestamp) {
        const actions = []
        const notifActions = notification.actions || []
        for (let i = 0; i < notifActions.length; i++) {
            const action = notifActions[i]
            actions.push({
                identifier: action ? action.identifier : "",
                text: action ? action.text : ""
            })
        }

        return {
            entryKey: entryKey,
            app: notification.appName || "",
            appIcon: notification.appIcon || "",
            summary: notification.summary || "",
            body: notification.body || "",
            image: notification.image || "",
            actionsJson: JSON.stringify(actions),
            urgency: notification.urgency,
            expireTimeout: notification.expireTimeout,
            timestamp: timestamp
        }
    }

    function indexOfKey(model, entryKey) {
        for (let i = 0; i < model.count; i++) {
            if (model.get(i).entryKey === entryKey)
                return i
        }
        return -1
    }

    function insertSnapshot(model, snapshot) {
        const existing = indexOfKey(model, snapshot.entryKey)
        if (existing >= 0) {
            updateSnapshot(model, snapshot)
            return
        }
        model.insert(0, snapshot)
    }

    function updateSnapshot(model, snapshot) {
        const index = indexOfKey(model, snapshot.entryKey)
        if (index < 0)
            return

        const roles = [
            "app", "appIcon", "summary", "body", "image",
            "actionsJson", "urgency", "expireTimeout", "timestamp"
        ]
        for (let i = 0; i < roles.length; i++)
            model.setProperty(index, roles[i], snapshot[roles[i]])
    }

    function refreshNotification(entryKey) {
        const notification = service.liveRefs[entryKey]
        if (!notification)
            return

        let timestamp = Date.now()
        const historyIndex = indexOfKey(historyModel, entryKey)
        if (historyIndex >= 0)
            timestamp = historyModel.get(historyIndex).timestamp

        const snapshot = makeSnapshot(notification, entryKey, timestamp)
        updateSnapshot(historyModel, snapshot)
        updateSnapshot(popupModel, snapshot)
    }

    function watchForUpdates(notification, entryKey) {
        const signals = [
            "summaryChanged", "bodyChanged", "appNameChanged", "appIconChanged",
            "imageChanged", "urgencyChanged", "expireTimeoutChanged", "hintsChanged"
        ]

        for (let i = 0; i < signals.length; i++) {
            const signal = notification[signals[i]]
            if (signal && typeof signal.connect === "function")
                signal.connect(() => service.refreshNotification(entryKey))
        }
    }

    function destroyPopupTimer(entryKey) {
        const timer = service.popupTimers[entryKey]
        if (timer) {
            timer.destroy()
            delete service.popupTimers[entryKey]
        }
    }

    function schedulePopupTimer(snapshot) {
        const duration = durationFor(snapshot.urgency, snapshot.expireTimeout)
        if (duration <= 0)
            return

        destroyPopupTimer(snapshot.entryKey)
        service.popupTimers[snapshot.entryKey] = timerComponent.createObject(service, {
            entryKey: snapshot.entryKey,
            interval: duration
        })
    }

    function trimPopups() {
        while (popupModel.count > service.maxPopups) {
            const last = popupModel.get(popupModel.count - 1)
            service.destroyPopupTimer(last.entryKey)
            popupModel.remove(popupModel.count - 1)
        }
    }

    function trimHistory() {
        while (historyModel.count > service.maxHistory)
            historyModel.remove(historyModel.count - 1)
    }

    function handleNotification(notification) {
        notification.tracked = true

        const timestamp = Date.now()
        const entryKey = String(notification.id) + "-" + String(timestamp)
        const snapshot = makeSnapshot(notification, entryKey, timestamp)

        service.liveRefs[entryKey] = notification
        watchForUpdates(notification, entryKey)

        notification.closed.connect(reason => {
            if (service.liveRefs[entryKey] === notification)
                delete service.liveRefs[entryKey]

            service.destroyPopupTimer(entryKey)
            if (reason === NotificationCloseReason.CloseRequested)
                service.removeFromHistory(entryKey)
        })

        insertSnapshot(historyModel, snapshot)
        trimHistory()

        if (!service.doNotDisturb) {
            insertSnapshot(popupModel, snapshot)
            schedulePopupTimer(snapshot)
            trimPopups()
        }
    }

    function expirePopup(entryKey) {
        const index = indexOfKey(popupModel, entryKey)
        if (index >= 0)
            popupModel.remove(index)

        service.destroyPopupTimer(entryKey)

        const notification = service.liveRefs[entryKey]
        if (notification && notification.tracked)
            notification.expire()
    }

    function dismissPopup(entryKey) {
        const index = indexOfKey(popupModel, entryKey)
        if (index >= 0)
            popupModel.remove(index)

        service.destroyPopupTimer(entryKey)

        const notification = service.liveRefs[entryKey]
        if (notification && notification.tracked)
            notification.dismiss()
    }

    function dismissFromCenter(entryKey) {
        const index = indexOfKey(historyModel, entryKey)
        if (index >= 0)
            historyModel.remove(index)

        service.dismissPopup(entryKey)
    }

    function removeFromHistory(entryKey) {
        const index = indexOfKey(historyModel, entryKey)
        if (index >= 0)
            historyModel.remove(index)

        const popupIndex = indexOfKey(popupModel, entryKey)
        if (popupIndex >= 0)
            popupModel.remove(popupIndex)

        service.destroyPopupTimer(entryKey)
    }

    function invokeDefault(entryKey) {
        const notification = service.liveRefs[entryKey]
        if (!notification)
            return

        const actions = notification.actions || []
        for (let i = 0; i < actions.length; i++) {
            if (actions[i] && actions[i].identifier === "default") {
                actions[i].invoke()
                break
            }
        }

        service.dismissPopup(entryKey)
    }

    function invokeAction(entryKey, identifier) {
        const notification = service.liveRefs[entryKey]
        if (!notification)
            return

        const actions = notification.actions || []
        for (let i = 0; i < actions.length; i++) {
            if (actions[i] && actions[i].identifier === identifier) {
                actions[i].invoke()
                break
            }
        }

        service.dismissPopup(entryKey)
    }

    function clearHistory() {
        for (const entryKey in service.popupTimers)
            service.destroyPopupTimer(entryKey)

        popupModel.clear()
        historyModel.clear()

        for (const entryKey in service.liveRefs) {
            const notification = service.liveRefs[entryKey]
            if (notification && notification.tracked)
                notification.dismiss()
        }
        service.liveRefs = ({})
    }

    NotificationServer {
        id: server
        keepOnReload: false
        imageSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        persistenceSupported: true

        onNotification: notification => service.handleNotification(notification)
    }
}
