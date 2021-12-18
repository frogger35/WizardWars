import { WebSocketServer } from 'ws';
import { v4 as uuidv4 } from 'uuid';
import arrayShuffle from 'array-shuffle';

const wss = new WebSocketServer({ port: 8080 });

const sockets = {}

const MAX_HEALTH = 50;
const MAX_SHIELD = 50;
const MAX_CARD_COPIES = 4;
const START_DECK_SIZE = 8;

//resource 0 = ice 1 = fire 2 = ice (see player builder)
//effect 0 = dam/heal 1 = shield 2 = resource 3 = resource gen
//target 0 = self 1 = enemy
//value how much effect
//cost hoe much resource
//spell destination (which resource is gained if effect is 2 or 3)

const CARDS = [
    { id: "ice1", cardName: "Weak Mana Shield", resource: 0, effect: 1, target: 0, value: 3, cost: 1, spellDestination: -1 }, 
    { id: "ice2", cardName: "Weak Heal", resource: 0, effect: 0, target:0, value: 7, cost: 2, spellDestination: -1 }, 
    { id: "ice3", cardName: "Ice Shield", resource: 0, effect: 1, target: 0, value: 3, cost: 3, spellDestination: -1 }, 
    { id: "ice5", cardName: "Heal", resource: 0, effect: 0, target:0, value: 5, cost: 1, spellDestination: -1 }, 
    { id: "ice6", cardName: "Conjure Ice Gem", resource: 0, effect: 3, target:0, value: 1, cost: 8, spellDestination: 0 }, 
    { id: "ice8", cardName: "Magical Barrier", resource: 0, effect: 1, target:0, value: 22, cost: 12, spellDestination: -1}, 
    { id: "ice9", cardName: "Greater Heal", resource: 0, effect: 0, target:0, value: 20, cost: 15, spellDestination: -1 }, 
    { id: "ice10", cardName: "Inspiration", resource: 0, effect: 0, target:0, value: 35, cost: 39, spellDestination: -1 }, 
    { id: "fire1", cardName: "Small Fireball", resource: 1, effect: 0, target:1, value: -6, cost: 2, spellDestination: -1 }, 
    { id: "fire2", cardName: "Fireball", resource: 1, effect: 0, target:1, value: -12, cost: 3, spellDestination: -1 }, 
    { id: "fire3", cardName: "Pyroblast", resource: 1, effect: 0, target:1, value: -15, cost: 4, spellDestination: -1 }, 
    { id: "fire4", cardName: "Conjure Fire Gem", resource: 1, effect: 3, target:0, value: 1, cost: 8, spellDestination: 1}, 
    { id: "fire5", cardName: "Scorch", resource: 1, effect: 0, target:1, value: -18, cost: 10, spellDestination: -1 }, 
    { id: "fire6", cardName: "Incinerate Stockpile", resource: 1, effect: 2, target:1, value: -4, cost: 12, spellDestination: 1 }, 
    { id: "fire8", cardName: "Fire Wave", resource: 1, effect: 0, target:1, value: -26, cost: 18, spellDestination: -1 }, 
    { id: "fire9", cardName: "Rain of Fire", resource: 1, effect: 0, target:1, value: -32, cost: 28, spellDestination: -1 },
    { id: "arcane1", cardName: "Conjure Ice Crystals", resource: 2, effect: 2, target:0, value: 8, cost: 4, spellDestination: 0 }, 
    { id: "arcane2", cardName: "Conjure Arcane Crystals", resource: 2, effect: 2, target:0, value: 8, cost: 4, spellDestination: 2 }, 
    { id: "arcane3", cardName: "Conjure Fire Crystals", resource: 2, effect: 2, target:0, value: 8, cost: 4, spellDestination: 1 }, 
    { id: "arcane4", cardName: "Destroy Ice Crystals", resource: 2, effect: 2, target:1, value: -8, cost: 4, spellDestination: 0 }, 
    { id: "arcane5", cardName: "Destroy Arcane Crystals", resource: 2, effect: 2, target:1, value: -8, cost: 4, spellDestination: 2 }, 
    { id: "arcane6", cardName: "Destroy Fire Crystals", resource: 2, effect: 2, target:1, value: -8, cost: 4, spellDestination: 1 }, 
    { id: "arcane7", cardName: "Conjure Arcane Gem", resource: 2, effect: 3, target:0, value: 1, cost: 8, spellDestination: 2}, 
    { id: "arcane8", cardName: "Arcane Elemental", resource: 2, effect: 0, target:1, value: -28, cost: 21, spellDestination: -1 }, 
    { id: "arcane9", cardName: "Ethereal Builders", resource: 2, cost: 22, effect: 0, target: 0, spellDestination: -1, value: 22 }, 
]

const findCard = (cardId) => {
    for (const card of CARDS) {
        if (cardId == card.id) { return card }
    }
}

const drawCards = () => {
    var availableCards = [];
    CARDS.forEach(card => {
        for (let index = 0; index < MAX_CARD_COPIES; index++) { availableCards.push(card.id); }
    });
    availableCards = arrayShuffle(availableCards);

    const deck1 = [];
    const deck2 = [];
    while (deck1.length < START_DECK_SIZE) {
        deck1.push(availableCards.shift());
        deck2.push(availableCards.shift());
    }
    return [deck1, deck2, availableCards];
}

const MESSAGES = {
    "sync": { cards: CARDS },
};

const matchQueue = [];
const matches = {};

const BuildMatch = (players, cards) => {
    return {
        players: players,
        matchId: uuidv4(),
        turnCounter: 0,
        playerTurn: 0,
        cards: cards,
        winner: null
    }
}

const BuildResource = (name) => {
    return {
        type: name,
        genRate: 3,
        value: 5
    }
}

const BuildPlayer = (socketId, cards) => {
    return {
        socketId: socketId,
        health: 50,
        shield: 0,
        resources: [ BuildResource("ice"), BuildResource("fire"), BuildResource("arcane")],
        cards: cards
    }
}

const MsgBuilder = (type, socketId) => {
    switch (type) {
        case "sync":
            return { msg: type, data: () => { return JSON.stringify({ ...MESSAGES[type], socketId: socketId, msg: type })  }}
        default:
            return { msg: 'error', data: "unrecognised msg type recieved" }
    }
};

const getMatchForTransit = (matchId) => {
    const match = matches[matchId];
    return {
        players: match.players,
        matchId: match.matchId,
        turnCounter: match.turnCounter,
        playerTurn: match.playerTurn,
        winner: match.winner
    }
}

wss.on('connection', function connection(ws) {
    ws.uuid = uuidv4();
    sockets[ws.uuid] = ws;

    const syncPkg = MsgBuilder("sync", ws.uuid);
    ws.send(syncPkg.data())

    ws.on('message', function message(data) {
        console.log('received: %s', data);

        const jsonData = JSON.parse(data);

        switch (jsonData.msg) {
            case "queue":
                matchQueue.push(ws.uuid);
                if (matchQueue.length >= 2) {
                    const cards = drawCards();
                    const players = [BuildPlayer(matchQueue.shift(), cards[0]), BuildPlayer(matchQueue.shift(), cards[1])]
                    const match = BuildMatch(players, cards[2]);
                    matches[match.matchId] = match;

                    players.forEach(player => { sockets[player.socketId].send(JSON.stringify({ ...getMatchForTransit(match.matchId), msg: 'matchFound'})); });
                }
                return;
            case "play-card":
                console.log("hello play card");
                const match = matches[jsonData.matchId];
                if (match.players[match.playerTurn].socketId == ws.uuid) {

                    const player = match.players[match.playerTurn];
                    const card = findCard(jsonData.cardId);

                    if (player.resources[card.resource].value - card.cost < 0) {
                        ws.send(JSON.stringify({ msg: "error", value: "not enough resource" }))
                        return;
                    }
                    player.resources[card.resource].value = player.resources[card.resource].value - card.cost

                    let index = 0;
                    for (index = 0; index < player.cards.length; index++) {
                        if (player.cards[index] == jsonData.cardId) { break; }
                    }
                    player.cards.splice(index, 1, match.cards.shift());

                   
                   const targetPlayer = (card.target == 0 ? player : match.players[Math.abs(match.playerTurn - 1)])

                   switch (card.effect) {
                        case 0: //heal / damage
                            var remainingDamage = card.value;
                            if (card.value < 0) {
                                if (targetPlayer.shield > 0) {
                                    targetPlayer.shield = targetPlayer.shield + card.value;
                                    if (targetPlayer.shield < 0) { 
                                        remainingDamage = targetPlayer.shield;
                                        targetPlayer.shield = 0; 
                                    } else { remainingDamage = 0; }
                                }
                            }
                            targetPlayer.health = targetPlayer.health + remainingDamage;
                            if (targetPlayer.health > MAX_HEALTH) { targetPlayer.health = MAX_HEALTH; }
                            if (targetPlayer.health <= 0) { match.winner = player.socketId; }
                            break;

                        case 1: //mana shield
                            targetPlayer.shield = targetPlayer.shield + card.value
                            if (targetPlayer.shield > MAX_SHIELD) { targetPlayer.sheidl = MAX_SHIELD }
                            break;

                        case 2: //resource
                            targetPlayer.resources[card.spellDestination].value = targetPlayer.resources[card.spellDestination].value + card.value;
                            break;

                        case 3: //resource generation
                            targetPlayer.resources[card.spellDestination].genRate = targetPlayer.resources[card.spellDestination].genRate + card.value;
                            break;
                   }

                   match.playerTurn = Math.abs(match.playerTurn - 1);
                   match.turnCounter = match.turnCounter + 1;

                   player.resources.forEach(resource => {
                    resource.value = resource.value + resource.genRate;
                    })

                   match.players.forEach(player => { sockets[player.socketId].send(JSON.stringify({ ...getMatchForTransit(match.matchId), msg: 'card-played'})); });

                } else { ws.send(JSON.stringify({ msg: "error", value: "not your turn" })) }
                return;
            default:
                console.log("Recieved an unknown message.")
        }
    });

    
});