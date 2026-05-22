// ConfigGeneral.qml
import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import QtQuick.Dialogs 6.3
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0

Item {
    id: generalPage
    Layout.fillWidth: true

    //Property-Aliases
    property alias cfg_enableTransparency: transparencyCheckbox.checked
    property alias cfg_showCoinPricesOnly: showCoinPricesOnlyCheckbox.checked
    property alias cfg_cryptoList: cryptoListField.text
    property alias cfg_updateInterval: updateIntervalField.value
    property alias cfg_customTitle: customTitleField.text
    property alias cfg_headerColor: headerColorField.text
    property alias cfg_positiveColor: positiveColorField.text
    property alias cfg_negativeColor: negativeColorField.text

    property var portfolioData: ({})
    property bool initialLoadComplete: false

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            CheckBox {
                id: transparencyCheckbox
                text: i18n("Enable transparency")
                Kirigami.FormData.label: i18n("Background:")
            }

            CheckBox {
                id: showCoinPricesOnlyCheckbox
                text: i18n("Show Coin Prices Only")
                Kirigami.FormData.label: i18n("Display:")
            }

            TextField {
                id: customTitleField
                Kirigami.FormData.label: i18n("Widget Title:")
                placeholderText: i18n("My Cryptonite")
            }

            // Cryptocurrencies
            RowLayout {
                Kirigami.FormData.label: i18n("Cryptocurrencies:")

                TextField {
                    id: cryptoListField
                    placeholderText: "BTC,ETH,XRP"
                    Layout.fillWidth: true
                    onTextChanged: {
                        if (initialLoadComplete) {
                            updatePortfolioRepeater();
                        }
                    }
                }

                HelpButton {
                    page: "general"
                }
            }

            SpinBox {
                id: updateIntervalField
                Kirigami.FormData.label: i18n("Update Interval (seconds):")
                from: 10
                to: 3600
                stepSize: 10
            }

            // Header Color
            RowLayout {
                Kirigami.FormData.label: i18n("Header Color:")

                TextField {
                    id: headerColorField
                    placeholderText: "white"
                    Layout.fillWidth: true
                }

                ColorChooser {
                    onColorSelected: function(color) {
                        headerColorField.text = color;
                    }
                }
            }

            // Positive Color
            RowLayout {
                Kirigami.FormData.label: i18n("Positive Color:")

                TextField {
                    id: positiveColorField
                    placeholderText: "#c6f4c6"
                    Layout.fillWidth: true
                }

                ColorChooser {
                    onColorSelected: function(color) {
                        positiveColorField.text = color;
                    }
                }
            }

            // Negative Color
            RowLayout {
                Kirigami.FormData.label: i18n("Negative Color:")

                TextField {
                    id: negativeColorField
                    placeholderText: "#f4a4a4"
                    Layout.fillWidth: true
                }

                ColorChooser {
                    onColorSelected: function(color) {
                        negativeColorField.text = color;
                    }
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Kirigami.Heading {
            level: 3
            text: i18n("Portfolio")
            Layout.fillWidth: true
        }

        // Portfolio-Einträge
        ColumnLayout {
            id: portfolioContainer
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                id: portfolioRepeater
                model: []

                delegate: RowLayout {
                    Layout.fillWidth: true
                    property string symbol: modelData

                    Label {
                        text: symbol + ":"
                        Layout.preferredWidth: 80
                    }

                    TextField {
                        id: amountField
                        placeholderText: i18n("Amount (e.g. 0.009336)")
                        Layout.fillWidth: true
                        text: generalPage.portfolioData[symbol] ? generalPage.portfolioData[symbol].amount.toString() : ""
                        onEditingFinished: updatePortfolioEntry(symbol, text, priceField.text)
                    }

                    TextField {
                        id: priceField
                        placeholderText: i18n("Purchase Price per coin (e.g. $53555.48)")
                        Layout.fillWidth: true
                        text: {
                            var item = generalPage.portfolioData[symbol];
                            if (item && item.purchasePrice) {
                                return item.purchasePrice.toFixed(2);
                            }
                            return "";
                        }
                        onEditingFinished: updatePortfolioEntry(symbol, amountField.text, text)
                    }
                }
            }
        }
    }

    function updatePortfolioRepeater() {
        var symbols = cryptoListField.text.split(',').filter(s => s.trim() !== '');
        portfolioRepeater.model = symbols;
    }

    function updatePortfolioEntry(symbol, amountStr, purchasePriceStr) {
        // Robuste Parsing-Logik
        var amount = parseFloat(amountStr.replace(',', '.'));
        var purchasePrice = parseFloat(purchasePriceStr.replace(',', '.').replace('$', '').trim());

        console.log("Updating portfolio:", symbol, "Amount:", amount, "Purchase Price:", purchasePrice);

        if (!isNaN(amount) && !isNaN(purchasePrice) && amount > 0 && purchasePrice > 0) {
            var roundedAmount = parseFloat(amount.toFixed(8));
            var roundedPurchasePrice = parseFloat(purchasePrice.toFixed(2));
            var invested = roundedAmount * roundedPurchasePrice;

            portfolioData[symbol] = {
                amount: roundedAmount,
                invested: invested,
                purchasePrice: roundedPurchasePrice
            };

            console.log("Portfolio updated:", symbol, portfolioData[symbol]);
        } else {
            console.log("Invalid portfolio data - deleting:", symbol, "Amount:", amount, "Price:", purchasePrice);
            delete portfolioData[symbol];
        }

        plasmoid.configuration.portfolio = JSON.stringify(portfolioData);

        if (typeof cryptoEngine !== 'undefined' && cryptoEngine.calculatePortfolio) {
            cryptoEngine.calculatePortfolio();
        }
    }

    function loadPortfolioData() {
        try {
            portfolioData = JSON.parse(plasmoid.configuration.portfolio || "{}");
        } catch (e) {
            portfolioData = {};
            console.log("Error loading portfolio:", e);
        }
        updatePortfolioRepeater();
    }

    Component.onCompleted: {
        // Konfiguration laden
        transparencyCheckbox.checked = plasmoid.configuration.enableTransparency;
        showCoinPricesOnlyCheckbox.checked = plasmoid.configuration.showCoinPricesOnly;
        customTitleField.text = plasmoid.configuration.customTitle || i18n("My Cryptonite");
        cryptoListField.text = plasmoid.configuration.cryptoList || "BTC,ETH";
        updateIntervalField.value = plasmoid.configuration.updateInterval || 60;
        headerColorField.text = plasmoid.configuration.headerColor || "white";
        positiveColorField.text = plasmoid.configuration.positiveColor || "#c6f4c6";
        negativeColorField.text = plasmoid.configuration.negativeColor || "#f4a4a4";

        // Portfolio laden
        loadPortfolioData();
        initialLoadComplete = true;
    }
}
