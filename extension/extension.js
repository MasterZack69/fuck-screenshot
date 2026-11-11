import Gettext from 'gettext';

import {Extension, InjectionManager} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as MessageTray from 'resource:///org/gnome/shell/ui/messageTray.js';

export default class FuckScreenshotExtension extends Extension {
    enable() {
        this._injectionManager = new InjectionManager();

        const expectedTitle = Gettext.dgettext('gnome-shell', 'Screenshot captured');
        const expectedSource = Gettext.dgettext('gnome-shell', 'Screenshot');

        this._injectionManager.overrideMethod(
            MessageTray.Source.prototype,
            'addNotification',
            originalAddNotification => {
                return function (notification) {
                    const isScreenshotNotification =
                        notification?.title === expectedTitle ||
                        notification?.title === 'Screenshot captured' ||
                        this.title === expectedSource ||
                        this.title === 'Screenshot';

                    if (isScreenshotNotification) {
                        notification?.destroy(
                            MessageTray.NotificationDestroyedReason.DISMISSED
                        );
                        return;
                    }

                    return originalAddNotification.call(this, notification);
                };
            }
        );
    }

    disable() {
        this._injectionManager?.clear();
        this._injectionManager = null;
    }
}
