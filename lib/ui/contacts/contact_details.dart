import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:event_taxi/event_taxi.dart';

import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/bus/events.dart';
import 'package:kalium_wallet_flutter/model/db/contact.dart';
import 'package:kalium_wallet_flutter/model/db/appdb.dart';
import 'package:kalium_wallet_flutter/ui/send/send_sheet.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/ui/widgets/auto_resize_text.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:kalium_wallet_flutter/ui/widgets/dialog.dart';
import 'package:kalium_wallet_flutter/ui/widgets/sheets.dart';
import 'package:kalium_wallet_flutter/util/caseconverter.dart';

// Contact Details Sheet
class ContactDetailsSheet {
  Contact contact;
  String documentsDirectory;

  ContactDetailsSheet(this.contact, this.documentsDirectory);

  // State variables
  bool _addressCopied = false;
  // Timer reference so we can cancel repeated events
  Timer _addressCopiedTimer;

  mainBottomSheet(BuildContext context) {
    AppSheets.showAppHeightNineSheet(
        context: context,
        animationDurationMs: 200,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Trashcan Button
                    Container(
                      width: 50,
                      height: 50,
                      margin: EdgeInsets.only(top: 10.0, left: 10.0),
                      child: FlatButton(
                        highlightColor:
                            StateContainer.of(context).curTheme.text15,
                        splashColor: StateContainer.of(context).curTheme.text15,
                        onPressed: () {
                          AppDialogs.showConfirmDialog(
                              context,
                              AppLocalization.of(context).removeContact,
                              AppLocalization.of(context)
                                  .removeContactConfirmation
                                  .replaceAll('%1', contact.name),
                              CaseChange.toUpperCase(
                                  AppLocalization.of(context).yes, context),
                              () {
                            DBHelper dbHelper = DBHelper();
                            dbHelper.deleteContact(contact).then((deleted) {
                              if (deleted) {
                                // Delete image if exists
                                if (contact.monkeyPath != null) {
                                  if (File(
                                          "$documentsDirectory/${contact.monkeyPath}")
                                      .existsSync()) {
                                    File("$documentsDirectory/${contact.monkeyPath}")
                                        .delete();
                                  }
                                }
                                EventTaxiImpl.singleton().fire(
                                    ContactRemovedEvent(contact: contact));
                                EventTaxiImpl.singleton().fire(
                                    ContactModifiedEvent(contact: contact));
                                UIUtil.showSnackbar(
                                    AppLocalization.of(context)
                                        .contactRemoved
                                        .replaceAll("%1", contact.name),
                                    context);
                                Navigator.of(context).pop();
                              } else {
                                // TODO - error for failing to delete contact
                              }
                            });
                          },
                              cancelText: CaseChange.toUpperCase(
                                  AppLocalization.of(context).no, context));
                        },
                        child: Icon(AppIcons.trashcan,
                            size: 24,
                            color: StateContainer.of(context).curTheme.text),
                        padding: EdgeInsets.all(13.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100.0)),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                      ),
                    ),
                    // The header of the sheet
                    Container(
                      margin: EdgeInsets.only(top: 25.0),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 140),
                      child: Column(
                        children: <Widget>[
                          AutoSizeText(
                            CaseChange.toUpperCase(
                                AppLocalization.of(context).contactHeader,
                                context),
                            style: AppStyles.textStyleHeader(context),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            stepGranularity: 0.1,
                          ),
                        ],
                      ),
                    ),
                    // Search Button
                    Container(
                      width: 50,
                      height: 50,
                      margin: EdgeInsets.only(top: 10.0, right: 10.0),
                      child: FlatButton(
                        highlightColor:
                            StateContainer.of(context).curTheme.text15,
                        splashColor: StateContainer.of(context).curTheme.text15,
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) {
                            return UIUtil.showAccountWebview(
                                context, contact.address);
                          }));
                        },
                        child: Icon(AppIcons.search,
                            size: 24,
                            color: StateContainer.of(context).curTheme.text),
                        padding: EdgeInsets.all(13.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100.0)),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                      ),
                    ),
                  ],
                ),

                // The main container that holds monKey, Contact Name and Contact Address
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // monKey container
                      contact.monkeyWidgetLarge != null
                          ? contact.monkeyWidgetLarge
                          : SizedBox(
                              width: smallScreen(context) ? 130 : 200,
                              height: smallScreen(context) ? 130 : 200),
                      // Contact Name container
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.105,
                          right: MediaQuery.of(context).size.width * 0.105,
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 25.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: StateContainer.of(context)
                              .curTheme
                              .backgroundDarkest,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          contact.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.0,
                            color: StateContainer.of(context).curTheme.primary,
                            fontFamily: 'NunitoSans',
                          ),
                        ),
                      ),
                      // Contact Address
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              new ClipboardData(text: contact.address));
                          setState(() {
                            _addressCopied = true;
                          });
                          if (_addressCopiedTimer != null) {
                            _addressCopiedTimer.cancel();
                          }
                          _addressCopiedTimer =
                              new Timer(const Duration(milliseconds: 800), () {
                            setState(() {
                              _addressCopied = false;
                            });
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.105,
                              right: MediaQuery.of(context).size.width * 0.105,
                              top: 15),
                          padding: EdgeInsets.symmetric(
                              horizontal: 25.0, vertical: 15.0),
                          decoration: BoxDecoration(
                            color: StateContainer.of(context)
                                .curTheme
                                .backgroundDarkest,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: UIUtil.threeLineAddressText(
                              context, contact.address,
                              type: _addressCopied
                                  ? ThreeLineAddressTextType.SUCCESS_FULL
                                  : ThreeLineAddressTextType.PRIMARY),
                        ),
                      ),
                      // Address Copied text container
                      Container(
                        margin: EdgeInsets.only(top: 5, bottom: 5),
                        child: Text(
                            _addressCopied
                                ? AppLocalization.of(context).addressCopied
                                : "",
                            style: TextStyle(
                              fontSize: 14.0,
                              color:
                                  StateContainer.of(context).curTheme.success,
                              fontFamily: 'NunitoSans',
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ],
                  ),
                ),

                // A column with "Send" and "Close" buttons
                Container(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          // Send Button
                          AppButton.buildAppButton(
                              context,
                              AppButtonType.PRIMARY,
                              AppLocalization.of(context).send,
                              Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                            Navigator.of(context).pop();
                            AppSendSheet(contact: contact)
                                .mainBottomSheet(context);
                          }),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          // Close Button
                          AppButton.buildAppButton(
                              context,
                              AppButtonType.PRIMARY_OUTLINE,
                              AppLocalization.of(context).close,
                              Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                            Navigator.pop(context);
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          });
        });
  }
}
