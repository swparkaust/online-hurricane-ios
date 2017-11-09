from twisted.internet.protocol import Factory, Protocol
from twisted.internet import reactor
from struct import *
from collections import deque
from random import shuffle
from twisted.internet.task import LoopingCall
from time import time

MESSAGE_PLAYER_CONNECTED = 0
MESSAGE_NOT_IN_MATCH = 1
MESSAGE_START_MATCH = 2
MESSAGE_MATCH_STARTED = 3
MESSAGE_ACTIVATE_PLAYER = 4
MESSAGE_TURNED_CARD = 5
MESSAGE_PLAYER_TURNED_CARD = 6
MESSAGE_DID_SLAP = 7
MESSAGE_PLAYER_CLAIMED_PILE = 8
MESSAGE_PLAYER_DISCARDED_CARD = 9
MESSAGE_GAME_OVER = 10
MESSAGE_RESTART_MATCH = 11
MESSAGE_NOTIFY_READY = 12
MESSAGE_QUIT_MATCH = 13
MESSAGE_CHAT = 14

MATCH_STATE_ACTIVE = 0
MATCH_STATE_GAME_OVER = 1

SECS_FOR_SHUTDOWN = 30

def chunks(l, n):
    """ Yield successive n-sized chunks from l.
    """
    for i in xrange(0, len(l), n):
        yield l[i:i+n]

class MessageReader:
	
	def __init__(self, data):
		self.data = data
		self.offset = 0

	def readByte(self):
		retval = unpack('!B', self.data[self.offset:self.offset+1])[0]
		self.offset = self.offset + 1
		return retval

	def readInt(self):
		retval = unpack('!I', self.data[self.offset:self.offset+4])[0]
		self.offset = self.offset + 4
		return retval

	def readString(self):
		strLength = self.readInt()
		unpackStr = '!%ds' % (strLength)
		retval = unpack(unpackStr, self.data[self.offset:self.offset+strLength])[0]
		self.offset = self.offset + strLength
		return retval

class MessageWriter:
	
	def __init__(self):
		self.data = ""

	def writeByte(self, value):
		self.data = self.data + pack('!B', value)

	def writeInt(self, value):
		self.data = self.data + pack('!I', value)

	def writeString(self, value):
		self.writeInt(len(value))
		packStr = '!%ds' % (len(value))
		self.data = self.data + pack(packStr, value)

class OnlineSandwichesMatch:

	def __init__(self, players):
		self.players = players
		self.state = MATCH_STATE_ACTIVE
		self.pendingShutdown = False
		self.shutdownTime = 0
		self.timer = LoopingCall(self.update)
		self.timer.start(5)
		self.clear()

	def __repr__(self):
		return "%d %s" % (self.state, str(self.players))

	def clear(self):
		self.pile = []
		self.chanceCount = 0
		self.currentPlayerIndex = 0
		self.previousPlayerIndex = -1
		d = []
		for suit in xrange(4):
			for rank in xrange(13):
				d.append((rank, suit))
		shuffle(d)
		chunklist = list(chunks(d, len(d) / len(self.players)))
		for i in range(0, len(self.players)):
			matchPlayer = self.players[i]
			matchPlayer.deck = chunklist[i]
			matchPlayer.score = len(chunklist[i])

	def write(self, message):
		message.writeByte(self.state)
		message.writeByte(len(self.players))
		for matchPlayer in self.players:
			matchPlayer.write(message)

	def turnedCard(self, player):
		if (self.state == MATCH_STATE_GAME_OVER):
			return
		if (self.currentPlayerIndex != player.match.players.index(player)):
			return
		self.pile.append(player.deck[-1])
		player.score -= 1
		del player.deck[-1]
		for p in self.players:
			if (len(p.deck) + len(self.pile) == 52):
				self.state = MATCH_STATE_GAME_OVER
				for matchPlayer in self.players:
					if (matchPlayer.protocol):
						matchPlayer.protocol.sendGameOver(player.match.players.index(p), p.score)
				break
		for i in range(0, len(self.players)):
			matchPlayer = self.players[i]
			if (matchPlayer.protocol):
				matchPlayer.protocol.sendPlayerTurnedCard(player.match.players.index(player), self.pile[-1][0], self.pile[-1][1], player.score)
		if 1 <= self.pile[-1][0] <= 9:
			if self.chanceCount > 0:
				self.chanceCount -= 1
				if self.chanceCount == 0:
					self.pile.reverse()
					self.players[self.previousPlayerIndex].deck = self.pile+self.players[self.previousPlayerIndex].deck
					self.players[self.previousPlayerIndex].score += len(self.pile)
					del self.pile[:]
					for matchPlayer in self.players:
						if (matchPlayer.protocol):
							matchPlayer.protocol.sendPlayerClaimedPile(self.previousPlayerIndex, self.players[self.previousPlayerIndex].score)
							matchPlayer.protocol.sendActivatePlayer(self.previousPlayerIndex)
					self.currentPlayerIndex = self.previousPlayerIndex
				elif len(player.deck) > 0:
					playerIndex = player.match.players.index(player)
					for matchPlayer in self.players:
						if (matchPlayer.protocol):
							matchPlayer.protocol.sendActivatePlayer(playerIndex)
					self.currentPlayerIndex = playerIndex
				else:
					a = deque(self.players)
					a.rotate(-(player.match.players.index(player) + 1))
					for elem in a:
						if len(elem.deck) > 0:
							playerIndex = player.match.players.index(elem)
							for matchPlayer in self.players:
								if (matchPlayer.protocol):
									matchPlayer.protocol.sendActivatePlayer(playerIndex)
							self.currentPlayerIndex = playerIndex
							break
				return
		a = deque(self.players)
		a.rotate(-(player.match.players.index(player) + 1))
		for elem in a:
			if len(elem.deck) > 0:
				playerIndex = player.match.players.index(elem)
				for matchPlayer in self.players:
					if (matchPlayer.protocol):
						matchPlayer.protocol.sendActivatePlayer(playerIndex)
				self.currentPlayerIndex = playerIndex
				break
		if self.pile[-1][0] == 10:
			self.chanceCount = 1
		elif self.pile[-1][0] == 11:
			self.chanceCount = 2
		elif self.pile[-1][0] == 12:
			self.chanceCount = 3
		elif self.pile[-1][0] == 0:
			self.chanceCount = 4
		else:
			pass
		self.previousPlayerIndex = player.match.players.index(player)

	def didSlap(self, player):
		if (self.state == MATCH_STATE_GAME_OVER):
			return
		if ((len(self.pile) >= 2 and 
			self.pile[-1][0] == self.pile[-2][0]) or
			(len(self.pile) >= 3 and 
			self.pile[-1][0] == self.pile[-3][0])):
			self.pile.reverse()
			player.deck = self.pile+player.deck
			player.score += len(self.pile)
			del self.pile[:]
			playerIndex = player.match.players.index(player)
			for matchPlayer in self.players:
				if (matchPlayer.protocol):
					matchPlayer.protocol.sendPlayerClaimedPile(playerIndex, player.score)
					matchPlayer.protocol.sendActivatePlayer(playerIndex)
			self.currentPlayerIndex = playerIndex
			self.chanceCount = 0
		else:
			if (len(player.deck) > 0 and len(self.pile) > 0):
				self.pile.insert(0, player.deck[-1])
				player.score -= 1
				del player.deck[-1]
				for p in self.players:
					if (len(p.deck) + len(self.pile) == 52):
						self.state = MATCH_STATE_GAME_OVER
						for matchPlayer in self.players:
							if (matchPlayer.protocol):
								matchPlayer.protocol.sendGameOver(player.match.players.index(p), p.score)
						break
				for matchPlayer in self.players:
					if (matchPlayer.protocol):
						matchPlayer.protocol.sendPlayerDiscardedCard(player.match.players.index(player), self.pile[0][0], self.pile[0][1], player.score)

	def restartMatch(self, player):
		if (self.state == MATCH_STATE_ACTIVE):
			return
		self.state = MATCH_STATE_ACTIVE
		self.clear()
		for matchPlayer in self.players:
			if (matchPlayer.protocol):
				matchPlayer.protocol.sendMatchStarted(self)
				matchPlayer.protocol.sendActivatePlayer(0)

	def quitMatch(self, player):
		if (self.state == MATCH_STATE_GAME_OVER):
			return
		print "Quitting match!"
		self.quit()
		
	def chat(self, player, text):
		if (self.state == MATCH_STATE_GAME_OVER):
			return
		for matchPlayer in self.players:
			if (matchPlayer.protocol):
				matchPlayer.protocol.sendChat("{0}: {1}".format(player.alias[:-1], text))

	def update(self):
		print "Match update: %s" % (str(self))
		if (self.pendingShutdown):
			cancelShutdown = True
			for player in self.players:
				if player.protocol == None:
					cancelShutdown = False
			if (time() > self.shutdownTime):
				print "Time elapsed, shutting down match"
				self.quit()
		else:
			for player in self.players:
				if player.protocol == None:
					print "Player %s disconnected, scheduling shutdown" % (player.alias)
					self.pendingShutdown = True
					self.shutdownTime = time() + SECS_FOR_SHUTDOWN

	def quit(self):
		self.timer.stop()
		for matchPlayer in self.players:
			matchPlayer.match = None
			if matchPlayer.protocol:
				matchPlayer.protocol.sendNotInMatch()

class OnlineSandwichesPlayer:
	
	def __init__(self, protocol, playerId, alias):
		self.protocol = protocol
		self.playerId = playerId
		self.alias = alias
		self.match = None
		self.deck = []
		self.score = 0

	def __repr__(self):
		return "%s:%s" % (self.alias, self.deck)

	def write(self, message):
		message.writeString(self.playerId)
		message.writeString(self.alias)
		message.writeByte(len(self.deck))
		for card in self.deck:
			message.writeInt(card[0])
			message.writeInt(card[1])
		message.writeInt(self.score)

class OnlineSandwichesFactory(Factory):
	
	def __init__(self):
		self.protocol = OnlineSandwichesProtocol
		self.players = []

	def connectionLost(self, protocol):
		for existingPlayer in self.players:
			if existingPlayer.protocol == protocol:
				existingPlayer.protocol = None

	def playerConnected(self, protocol, playerId, alias, continueMatch):
		for existingPlayer in self.players:
			if existingPlayer.playerId == playerId:
				existingPlayer.protocol = protocol
				protocol.player = existingPlayer
				if (existingPlayer.match):
					if (continueMatch):
						existingPlayer.protocol.sendMatchStarted(existingPlayer.match)
						existingPlayer.protocol.sendActivatePlayer(existingPlayer.match.currentPlayerIndex)
					else:
						print "Quitting match!"
						existingPlayer.match.quit()
				else:
					existingPlayer.protocol.sendNotInMatch()
				return
		newPlayer = OnlineSandwichesPlayer(protocol, playerId, alias)
		protocol.player = newPlayer
		self.players.append(newPlayer)
		newPlayer.protocol.sendNotInMatch()

	def startMatch(self, playerIds):
		matchPlayers = []
		for existingPlayer in self.players:
			if existingPlayer.playerId in playerIds:
				if existingPlayer.match != None:
					return
				matchPlayers.append(existingPlayer)
		match = OnlineSandwichesMatch(matchPlayers)
		for matchPlayer in matchPlayers:
			matchPlayer.match = match
			matchPlayer.protocol.sendMatchStarted(match)
			matchPlayer.protocol.sendActivatePlayer(0)

	def notifyReady(self, player, inviter):
		for existingPlayer in self.players:
			if existingPlayer.playerId == inviter:
				existingPlayer.protocol.sendNotifyReady(player.playerId)

class OnlineSandwichesProtocol(Protocol):
	
	def __init__(self):
		self.inBuffer = ""
		self.player = None

	def log(self, message):
		if (self.player):
			print "%s: %s" % (self.player.alias, message)
		else:
			print "%s: %s" % (self, message)

	def connectionMade(self):
		self.log("Connection made")

	def connectionLost(self, reason):
		self.log("Connection lost: %s" % str(reason))
		self.factory.connectionLost(self)

	def sendMessage(self, message):
		msgLen = pack('!I', len(message.data))
		self.transport.write(msgLen)
		self.transport.write(message.data)

	def sendNotInMatch(self):
		message = MessageWriter()
		message.writeByte(MESSAGE_NOT_IN_MATCH)
		self.log("Sent MESSAGE_NOT_IN_MATCH")
		self.sendMessage(message)

	def sendMatchStarted(self, match):
		message = MessageWriter()
		message.writeByte(MESSAGE_MATCH_STARTED)
		match.write(message)
		self.log("Sent MATCH_STARTED %s" % (str(match)))
		self.sendMessage(message)

	def sendActivatePlayer(self, playerIndex):
		message = MessageWriter()
		message.writeByte(MESSAGE_ACTIVATE_PLAYER)
		message.writeByte(playerIndex)
		self.log("Sent ACTIVATE_PLAYER %d" % (playerIndex))
		self.sendMessage(message)

	def sendPlayerTurnedCard(self, playerIndex, rank, suit, playerScore):
		message = MessageWriter()
		message.writeByte(MESSAGE_PLAYER_TURNED_CARD)
		message.writeByte(playerIndex)
		message.writeInt(rank)
		message.writeInt(suit)
		message.writeInt(playerScore)
		self.log("Sent PLAYER_TURNED_CARD %d %d %d %d" % (playerIndex, rank, suit, playerScore))
		self.sendMessage(message)

	def sendPlayerClaimedPile(self, playerIndex, playerScore):
		message = MessageWriter()
		message.writeByte(MESSAGE_PLAYER_CLAIMED_PILE)
		message.writeByte(playerIndex)
		message.writeInt(playerScore)
		self.log("Sent PLAYER_CLAIMED_PILE %d %d" % (playerIndex, playerScore))
		self.sendMessage(message)

	def sendPlayerDiscardedCard(self, playerIndex, rank, suit, playerScore):
		message = MessageWriter()
		message.writeByte(MESSAGE_PLAYER_DISCARDED_CARD)
		message.writeByte(playerIndex)
		message.writeInt(rank)
		message.writeInt(suit)
		message.writeInt(playerScore)
		self.log("Sent PLAYER_DISCARDED_CARD %d %d %d %d" % (playerIndex, rank, suit, playerScore))
		self.sendMessage(message)

	def sendGameOver(self, winnerIndex, winnerScore):
		message = MessageWriter()
		message.writeByte(MESSAGE_GAME_OVER)
		message.writeByte(winnerIndex)
		message.writeInt(winnerScore)
		self.log("Sent MESSAGE_GAME_OVER %d %d" % (winnerIndex, winnerScore))
		self.sendMessage(message)

	def sendNotifyReady(self, playerId):
		message = MessageWriter()
		message.writeByte(MESSAGE_NOTIFY_READY)
		message.writeString(playerId)
		self.log("Sent PLAYER_NOTIFY_READY %s" % (playerId))
		self.sendMessage(message)
		
	def sendChat(self, text):
		message = MessageWriter()
		message.writeByte(MESSAGE_CHAT)
		message.writeString(text)
		self.log("Sent MESSAGE_CHAT %s" % (text))
		self.sendMessage(message)

	def startMatch(self, message):
		numPlayers = message.readByte()
		playerIds = []
		for i in range(0, numPlayers):
			playerId = message.readString()
			playerIds.append(playerId)
		self.log("Recv MESSAGE_START_MATCH %s" % (str(playerIds)))
		self.factory.startMatch(playerIds)

	def playerConnected(self, message):
		playerId = message.readString()
		alias = message.readString()
		continueMatch = message.readByte()
		self.log("Recv MESSAGE_PLAYER_CONNECTED %s %s %d" % (playerId, alias, continueMatch))
		self.factory.playerConnected(self, playerId, alias, continueMatch)

	def turnedCard(self, message):
		self.log("Recv MESSAGE_TURNED_CARD")
		self.player.match.turnedCard(self.player)

	def didSlap(self, message):
		self.log("Recv MESSAGE_DID_SLAP")
		self.player.match.didSlap(self.player)

	def restartMatch(self, message):
		self.log("Recv MESSAGE_RESTART_MATCH")
		self.player.match.restartMatch(self.player)

	def notifyReady(self, message):
		inviter = message.readString()
		self.log("Recv MESSAGE_NOTIFY_READY %s" % (inviter))
		self.factory.notifyReady(self.player, inviter)

	def quitMatch(self, message):
		self.log("Recv MESSAGE_QUIT_MATCH")
		self.player.match.quitMatch(self.player)
		
	def chat(self, message):
		text = message.readString()
		self.log("Recv MESSAGE_CHAT %s" % (text))
		self.player.match.chat(self.player, text)

	def processMessage(self, message):
		messageId = message.readByte()

		if messageId == MESSAGE_PLAYER_CONNECTED:
			return self.playerConnected(message)
		if messageId == MESSAGE_START_MATCH:
			return self.startMatch(message)
		if messageId == MESSAGE_NOTIFY_READY:
			return self.notifyReady(message)

		# Match specific messages
		if (self.player == None):
			self.log("Bailing - no player set")
			return
		if (self.player.match == None):
			self.log("Bailing - no match set")
			return
		if messageId == MESSAGE_TURNED_CARD:
			return self.turnedCard(message)
		if messageId == MESSAGE_DID_SLAP:
			return self.didSlap(message)
		if messageId == MESSAGE_RESTART_MATCH:
			return self.restartMatch(message)
		if messageId == MESSAGE_QUIT_MATCH:
			return self.quitMatch(message)
		if messageId == MESSAGE_CHAT:
			return self.chat(message)

		self.log("Unexpected message: %d" % (messageId))

	def dataReceived(self, data):
		
		self.inBuffer = self.inBuffer + data

		while(True):
			if (len(self.inBuffer) < 4):
				return;

			msgLen = unpack('!I', self.inBuffer[:4])[0]
			if (len(self.inBuffer) < msgLen):
				return;

			messageString = self.inBuffer[4:msgLen+4]
			self.inBuffer = self.inBuffer[msgLen+4:]

			message = MessageReader(messageString)
			self.processMessage(message)

factory = OnlineSandwichesFactory()
reactor.listenTCP(63520, factory)
print "Online Sandwiches server started"
reactor.run()