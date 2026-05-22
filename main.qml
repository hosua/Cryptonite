// main.qml
import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

    // Transparenter Hintergrund basierend auf der Konfiguration
    Plasmoid.backgroundHints: plasmoid.configuration.enableTransparency ?
    PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground

    // CryptoEngine muss hier definiert sein
    CryptoEngine {
        id: cryptoEngine
    }

    fullRepresentation: Item {
        width: 400
        height: cryptoEngine.cryptoData ? Object.keys(cryptoEngine.cryptoData).length * 80 + (plasmoid.configuration.showCoinPricesOnly ? 50 : 150) : 250

        // Transparenter Hintergrund Container
        Rectangle {
            anchors.fill: parent
            color: plasmoid.configuration.enableTransparency ? "transparent" : PlasmaCore.Theme.backgroundColor
            radius: 5
        }

        Column {
            anchors.fill: parent
            spacing: 5
            padding: 10

            // Zentrierte Überschrift
            Text {
                text: plasmoid.configuration.customTitle || "My Cryptonite"
                font.bold: true
                font.pixelSize: 16
                color: plasmoid.configuration.headerColor || PlasmaCore.Theme.textColor
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            // Liste der Kryptowährungen mit Portfolio-Informationen
            ListView {
                width: parent.width
                height: parent.height - (plasmoid.configuration.showCoinPricesOnly ? 50 : 150)
                model: Object.keys(cryptoEngine.cryptoData)
                delegate: Item {
                    width: ListView.view.width
                    height: 80

                    // RowLayout wurde durch Row ersetzt = bessere Kompatibilität
                    Row {
                        anchors.fill: parent
                        spacing: 10
                        padding: 5

                        // Linke Spalte: Allgemeine Crypto-Info
                        Column {
                            width: parent.width * 0.6
                            padding: 5

                            Text {
                                text: (cryptoEngine.cryptoData[modelData]?.name || modelData) + " (" + modelData + ")"
                                font.bold: true
                                color: plasmoid.configuration.headerColor || PlasmaCore.Theme.textColor
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: "$" + (cryptoEngine.cryptoData[modelData]?.price || 0).toFixed(2)
                                color: plasmoid.configuration.headerColor || PlasmaCore.Theme.textColor
                                width: parent.width
                            }

                            Text {
                                text: "24h: " + (cryptoEngine.cryptoData[modelData]?.change24h || 0).toFixed(2) + "%"
                                color: (cryptoEngine.cryptoData[modelData]?.change24h || 0) >= 0 ?
                                (plasmoid.configuration.positiveColor || "#c6f4c6") :
                                (plasmoid.configuration.negativeColor || "#f4a4a4")
                                width: parent.width
                            }
                        }

                        // Rechte Spalte: Portfolio-Info
                        Column {
                            width: parent.width * 0.4
                            padding: 5
                            visible: !plasmoid.configuration.showCoinPricesOnly && cryptoEngine && cryptoEngine.userHoldings && cryptoEngine.userHoldings[modelData]

                            Text {
                                text: "My Value: $" + (cryptoEngine.userHoldings && cryptoEngine.userHoldings[modelData] ?
                                (cryptoEngine.userHoldings[modelData].amount * cryptoEngine.cryptoData[modelData]?.price).toFixed(2) : "0.00")
                                font.bold: true
                                color: plasmoid.configuration.headerColor || PlasmaCore.Theme.textColor
                                width: parent.width
                                wrapMode: Text.Wrap
                            }

                            Text {
                                text: {
                                    if (!cryptoEngine.userHoldings || !cryptoEngine.userHoldings[modelData]) return "";

                                    var holding = cryptoEngine.userHoldings[modelData];
                                    var currentValue = holding.amount * (cryptoEngine.cryptoData[modelData]?.price || 0);
                                    var profitLoss = currentValue - holding.invested;
                                    var percentage = holding.invested > 0 ? (profitLoss / holding.invested * 100) : 0;

                                    var sign = profitLoss >= 0 ? "+" : "";
                                    return "P/L: " + sign + "$" + profitLoss.toFixed(2) +
                                    " (" + sign + percentage.toFixed(2) + "%)";
                                }
                                color: {
                                    if (!cryptoEngine.userHoldings || !cryptoEngine.userHoldings[modelData]) return "transparent";

                                    var holding = cryptoEngine.userHoldings[modelData];
                                    var currentValue = holding.amount * (cryptoEngine.cryptoData[modelData]?.price || 0);
                                    var profitLoss = currentValue - holding.invested;

                                    return profitLoss >= 0 ?
                                    (plasmoid.configuration.positiveColor || "#c6f4c6") :
                                    (plasmoid.configuration.negativeColor || "#f4a4a4");
                                }
                                width: parent.width
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }

            // Trennlinie
            Rectangle {
                width: parent.width
                height: 1
                color: plasmoid.configuration.headerColor || PlasmaCore.Theme.textColor
                opacity: 0.5
                visible: !plasmoid.configuration.showCoinPricesOnly
            }

            // Portfolio-Zusammenfassung mit Zeilenumbruch
            Column {
                width: parent.width
                spacing: 5
                visible: !plasmoid.configuration.showCoinPricesOnly

                Text {
                    text: "Total Value: $" + (cryptoEngine.totalCurrentValue || 0).toFixed(2)
                    font.bold: true
                    color: plasmoid.configuration.headerColor || PlasmaCore.Theme.textColor
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                Text {
                    text: "Invested: $" + (cryptoEngine.totalInvestment || 0).toFixed(2)
                    font.bold: true
                    color: plasmoid.configuration.headerColor || PlasmaCore.Theme.textColor
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                Text {
                    text: {
                        var profitLoss = cryptoEngine.totalProfitLoss || 0;
                        var investment = cryptoEngine.totalInvestment || 0;
                        var percentage = investment > 0 ? (profitLoss / investment * 100) : 0;

                        var sign = profitLoss >= 0 ? "+" : "";
                        return "Profit/Loss: " + sign + "$" + profitLoss.toFixed(2) +
                        " (" + sign + percentage.toFixed(2) + "%)";
                    }
                    color: (cryptoEngine.totalProfitLoss || 0) >= 0 ?
                    (plasmoid.configuration.positiveColor || "#c6f4c6") :
                    (plasmoid.configuration.negativeColor || "#f4a4a4")
                    width: parent.width
                    wrapMode: Text.Wrap
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: console.log("Cryptonite widget clicked!")
        }
    }
}
