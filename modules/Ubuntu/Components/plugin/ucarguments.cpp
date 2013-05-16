/*
 * Copyright 2013 Canonical Ltd.
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
 * Author: Florian Boucault <florian.boucault@canonical.com>
 */

#include "ucarguments.h"
#include <QtCore/QCoreApplication>
#include <QtCore/QDebug>
#include <QtCore/QTextStream>

UCArguments::UCArguments(QObject *parent) :
    QObject(parent),
    m_defaultArgument(NULL)
{
    m_rawArguments = QCoreApplication::arguments();
    qDebug() << "RAW ARGUMENTS" << m_rawArguments; // FIXME: remove
}

UCArgument* UCArguments::defaultArgument() const
{
    return m_defaultArgument;
}

void UCArguments::setDefaultArgument(UCArgument* argument)
{
    // FIXME
    m_defaultArgument = argument;
    Q_EMIT(defaultArgumentChanged());
}


void UCArguments::appendArguments(UCArgument* argument)
{
    m_arguments.append(argument);
    m_expectedArguments = buildExpectedArguments(m_arguments);
    m_argumentsValues = parseRawArguments(m_rawArguments, m_expectedArguments);
}

UCArgument* UCArguments::atArguments(int index)
{
    return m_arguments.at(index);
}

int UCArguments::countArguments()
{
    return m_arguments.size();
}

void UCArguments::clearArguments()
{
    m_arguments.clear();
    m_expectedArguments.clear();
    m_argumentsValues = parseRawArguments(m_rawArguments, m_expectedArguments);
}

void staticAppendArguments(QQmlListProperty<UCArgument>* property, UCArgument* argument)
{
    UCArguments* arguments = static_cast<UCArguments*>(property->data);
    arguments->appendArguments(argument);
}

UCArgument* staticAtArguments(QQmlListProperty<UCArgument>* property, int index)
{
    UCArguments* arguments = static_cast<UCArguments*>(property->data);
    return arguments->atArguments(index);
}

int staticCountArguments(QQmlListProperty<UCArgument>* property)
{
    UCArguments* arguments = static_cast<UCArguments*>(property->data);
    return arguments->countArguments();
}

void staticClearArguments(QQmlListProperty<UCArgument>* property)
{
    UCArguments* arguments = static_cast<UCArguments*>(property->data);
    arguments->clearArguments();
}

QQmlListProperty<UCArgument> UCArguments::arguments()
{
    return QQmlListProperty<UCArgument>(this, this, &staticAppendArguments,
                                        &staticCountArguments, &staticAtArguments,
                                        &staticClearArguments);
}

void UCArguments::quitAndPrintUsage(QString errorMessage)
{
    // FIXME: use i18n
    QString usage;
    QTextStream usageStream(&usage);
    // FIXME: guess application binary better
    QString applicationBinary = m_rawArguments[0];

    usageStream << QString("Usage: ");
    usageStream << applicationBinary << endl;
    usageStream << QString("Options:") << endl;

    // convert to char* to avoid qWarning printing out quotes ""
    qWarning() << errorMessage.toStdString().c_str();
    qWarning() << usage.toStdString().c_str();
    QCoreApplication::exit(-1);
}

QHash<QString, QStringList> UCArguments::buildExpectedArguments(QList<UCArgument*> declaredArguments)
{
    QHash<QString, QStringList> expectedArguments;
    UCArgument* argument;

    Q_FOREACH (argument, declaredArguments) {
        expectedArguments.insert(argument->name(), argument->valueNames());
    }

    return expectedArguments;
}

QHash<QString, QStringList> UCArguments::parseRawArguments(QStringList rawArguments, QHash<QString, QStringList> expectedArguments)
{
    // FIXME: break down in smaller functions
    QHash<QString, QStringList> argumentsValues;
    QString name;
    QStringList values;

    // ignore the first item in the rawArguments which is the name of the binary
    QStringList::const_iterator i;
    for (i = rawArguments.begin(), ++i; i != rawArguments.end(); ++i) {
        QString rawArgument = (*i);
        if (rawArgument.startsWith('-')) {
            if (!name.isEmpty()) {
                // insert values of previously parsed named argument
                argumentsValues.insert(name, values);
            }
            // it starts with a '-' therefore it is a named argument
            // remove all prepended '-'
            rawArgument = rawArgument.split('-', QString::SkipEmptyParts).join('-');
            // string after the '=' sign is a value for the argument
            values = rawArgument.split("=");
            name = values.takeAt(0);
        } else {
            if (!expectedArguments.contains(name) && values.empty()) {
                // unexpected named arguments are given at most one value
                values.append(rawArgument);
            } else if (values.size() < expectedArguments[name].size()) {
                // additional value for a named argument
                values.append(rawArgument);
            } else {
                if (!name.isEmpty()) {
                    // insert values of previously parsed named argument
                    argumentsValues.insert(name, values);
                }
                // default/unnamed argument
                argumentsValues[""].append(rawArgument);
            }
        }
    }

    qDebug() << "PARSING... "  << argumentsValues; // FIXME: remove
    return argumentsValues;
}
