// main.qml
import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: plasmoid.configuration.enableTransparency ?
    PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground

    CryptoEngine {
        id: cryptoEngine
    }

    fullRepresentation: Item {
        id: viewRoot
        width: 400

        property var cryptoKeys: cryptoEngine.cryptoData ? Object.keys(cryptoEngine.cryptoData) : []
        property bool useGrid: plasmoid.configuration.showCoinPricesOnly && plasmoid.configuration.showAsGrid
        property int gridSpacing: 8
        property int gridCardMinWidth: 120
        property int gridCardHeight: 72

        property int effectiveColumns: {
            if (!useGrid) return 1;
            if (plasmoid.configuration.smartGrid) {
                var avail = width - 20;
                return Math.max(1, Math.floor((avail + gridSpacing) / (gridCardMinWidth + gridSpacing)));
            }
            return Math.max(1, plasmoid.configuration.gridColumns || 2);
        }

        property int gridRows: cryptoKeys.length > 0
            ? Math.ceil(cryptoKeys.length / effectiveColumns)
            : 1

        height: {
            var count = cryptoKeys.length;
            if (count === 0) return 250;
            if (useGrid) {
                return gridRows * gridCardHeight
                    + Math.max(0, gridRows - 1) * gridSpacing
                    + 50;
            }
            return count * 80 + (plasmoid.configuration.showCoinPricesOnly ? 50 : 150);
        }

        Rectangle {
            anchors.fill: parent
            color: plasmoid.configuration.enableTransparency ? "transparent" : PlasmaCore.Theme.backgroundColor
            radius: 5
        }

        Column {
            anchors.fill: parent
            spacing: 5
            padding: 10

            // Title
            Text {
                text: plasmoid.configuration.customTitle || "My Cryptonite"
                font.bold: true
                font.pixelSize: 16
                color: plasmoid.configuration.headerColor || PlasmaCore.Theme.textColor
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            // Content area: list or grid
            Item {
                width: parent.width
                height: viewRoot.useGrid
                    ? (viewRoot.gridRows * viewRoot.gridCardHeight
                       + Math.max(0, viewRoot.gridRows - 1) * viewRoot.gridSpacing)
                    : parent.height - (plasmoid.configuration.showCoinPricesOnly ? 50 : 150)

                ListView {
                    anchors.fill: parent
                    visible: !viewRoot.useGrid
                    model: viewRoot.cryptoKeys

                    delegate: Item {
                        width: ListView.view.width
                        height: 80

                        Row {
                            anchors.fill: parent
                            spacing: 10
                            padding: 5

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

                GridView {
                    anchors.fill: parent
                    visible: viewRoot.useGrid
                    interactive: false
                    cellWidth: Math.floor(parent.width / viewRoot.effectiveColumns)
                    cellHeight: viewRoot.gridCardHeight
                    model: viewRoot.cryptoKeys

                    delegate: Item {
                        width: GridView.view.cellWidth
                        height: GridView.view.cellHeight

                        Rectangle {
                            anchors {
                                fill: parent
                                margins: viewRoot.gridSpacing / 2
                            }
                            color: "transparent"
                            radius: 4
                            border.width: 1
                            border.color: {
                                var c = Qt.color(plasmoid.configuration.headerColor || "white");
                                return Qt.rgba(c.r, c.g, c.b, 0.35);
                            }

                            Column {
                                anchors {
                                    fill: parent
                                    margins: 6
                                }
                                spacing: 2

                                Text {
                                    text: modelData
                                    font.bold: true
                                    font.pixelSize: 13
                                    color: plasmoid.configuration.headerColor || PlasmaCore.Theme.textColor
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "$" + (cryptoEngine.cryptoData[modelData]?.price || 0).toFixed(2)
                                    font.pixelSize: 12
                                    color: plasmoid.configuration.headerColor || PlasmaCore.Theme.textColor
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: (cryptoEngine.cryptoData[modelData]?.change24h || 0).toFixed(2) + "%"
                                    font.pixelSize: 12
                                    color: (cryptoEngine.cryptoData[modelData]?.change24h || 0) >= 0 ?
                                    (plasmoid.configuration.positiveColor || "#c6f4c6") :
                                    (plasmoid.configuration.negativeColor || "#f4a4a4")
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: plasmoid.configuration.headerColor || PlasmaCore.Theme.textColor
                opacity: 0.5
                visible: !plasmoid.configuration.showCoinPricesOnly
            }

            // Footer: total value, invested, profit/loss
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
