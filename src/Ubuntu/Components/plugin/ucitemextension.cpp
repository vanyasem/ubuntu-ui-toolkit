/*
 * Copyright 2015 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author: Zsombor Egri <zsombor.egri@canonical.com>
 */

#include "ucitemextension.h"
#include "ucstyleditembase_p.h"
#include "uctheme.h"
#include <QtQml/private/qqmlcomponentattached_p.h>
#include <QtGui/QGuiApplication>

/*
 * The UCItemExtension class provides faster theme change broadcast and saves us from
 * the need to connect to ascendant instances all around. It is meant to extend QQuickItem
 * (see plugin.cpp registration) therefore it extends any QtQuick element.
 * Whenever the extended Item's parentItem is changed, there will be an UCThemeUpdateEvent
 * event broadcasted to all item's children and their children. Components which need to
 * handle the theme change can therefore catch this event by extending the QObject::customEvent()
 * method and handle the event there.
 */

//#define ASYNC_BROADCAST
int UCThemeUpdateEvent::styledItemEventId = QEvent::registerEventType();
int UCThemeUpdateEvent::themeEventId = QEvent::registerEventType();
UCThemeUpdateEvent::UCThemeUpdateEvent(UCStyledItemBase *newStyled)
    : QEvent((QEvent::Type)UCThemeUpdateEvent::styledItemEventId)
    , m_ascendantStyled(newStyled)
    , m_theme(Q_NULLPTR)
{
}

UCThemeUpdateEvent::UCThemeUpdateEvent(UCTheme *theme)
    : QEvent((QEvent::Type)UCThemeUpdateEvent::themeEventId)
    , m_ascendantStyled(Q_NULLPTR)
    , m_theme(theme)
{
}

// boadcast parent change to the children recoursively
void UCThemeUpdateEvent::broadcastAscendantUpdate(QQuickItem *item, UCStyledItemBase *ascendantStyled)
{
    Q_FOREACH(QQuickItem *child, QQuickItemPrivate::get(item)->childItems) {
#ifdef ASYNC_BROADCAST
        QGuiApplication::postEvent(child, new UCThemeUpdateEvent(ascendantStyled));
#else
        UCThemeUpdateEvent event(ascendantStyled);
        QGuiApplication::sendEvent(child, &event);
#endif
        // StyledItem will handle the broadcast itself depending on whether the theme change was appropriate or not
        // and will complete the ascendantStyled/theme itself
        if (QQuickItemPrivate::get(child)->childItems.size() > 0) {// && !qobject_cast<UCStyledItemBase*>(child)) {
            broadcastAscendantUpdate(child, ascendantStyled);
        }
    }
}

void UCThemeUpdateEvent::broadcastThemeUpdate(QQuickItem *item, UCTheme *theme)
{
    Q_FOREACH(QQuickItem *child, item->childItems()) {
#ifdef ASYNC_BROADCAST
        QGuiApplication::postEvent(child, new UCThemeUpdateEvent(theme));
#else
        UCThemeUpdateEvent event(theme);
        QGuiApplication::sendEvent(child, &event);
#endif
        // StyledItem will handle the broadcast itself depending on whether the theme change was appropriate or not
        // and will complete the ascendantStyled/theme itself
        if (child->childItems().size() > 0 && !qobject_cast<UCStyledItemBase*>(child)) {
            broadcastThemeUpdate(child, theme);
        }
    }
}

/*************************************************************************
 *
 */
UCItemExtension::UCItemExtension(QObject *parent)
    : QObject(parent)
    , m_item(static_cast<QQuickItem*>(parent))
{
    connect(m_item, &QQuickItem::parentChanged, this, &UCItemExtension::extendedParentChanged);
    // get parent item changes
    connect(m_item, &QQuickItem::parentChanged, this, &UCItemExtension::handleParentChanged);
}

// handle parent changes
void UCItemExtension::handleParentChanged(QQuickItem *newParent)
{
    Q_UNUSED(newParent);
    // do not care about the closest StyledItem and theme as while teh event reaches the children
    // those will be completed.
    UCThemeUpdateEvent::broadcastAscendantUpdate(m_item, Q_NULLPTR);
}

// property overrides forward to the original the getter/setter
QQuickItem *UCItemExtension::parentItem() const
{
    return m_item->parentItem();
}
void UCItemExtension::setParentItem(QQuickItem *parentItem)
{
    m_item->setParentItem(parentItem);
}
