from secrets import DISCORD_TOKEN, SERVER_TOKEN, GENERAL_ID

import datetime
import discord

import schedule
import pickle
import os

first = True

first_dict = dict()
member_list = []

intents = discord.Intents.all()
intents.message_content = True

client = discord.Client(intents=intents)

# ----------------------------------------------------------------

def check_day():
    global first
    first = True
    print(first)

schedule.every().day.at("00:00", "Europe/Amsterdam").do(check_day)

# ----------------------------------------------------------------

def get_scoreboard():
    global first
    with open('scores.pkl', 'rb') as file:
        first_dict = pickle.load(file)
    global member_list
    result = []
    for member in member_list:
        if (first_dict[member.id] > 0):
            result.append(f'{member.display_name} : {first_dict[member.id]}')
    return ('\n'.join(result))

async def add_score(args, message):
    with open('scores.pkl', 'rb') as file:
        first_dict = pickle.load(file)
    global member_list
    id = 0
    for member in member_list:
        if (member.name == args[1]):
            id = member.id;
    if (id == 0):
        await message.channel.send('nom incorrect')
        return
    first_dict[id] = int(args[2])
    with open('scores.pkl', 'wb') as file:
        pickle.dump(first_dict, file)
    await message.channel.send(f'{args[1]} a désormais {first_dict[id]} first')

@client.event
async def on_message(message):
    global schedule
    schedule.run_pending()
    global first
    if message.content.split()[0] == '!set_first':
        await add_score(message.content.split(), message)
    if message.content == '!first_scoreboard':
        await message.channel.send(get_scoreboard())
    if first == False or message.channel.id != GENERAL_ID:
        return
    if message.author == client.user:
        return
    with open('scores.pkl', 'rb') as file:
        first_dict = pickle.load(file)
    first_dict[message.author.id] += 1
    with open('scores.pkl', 'wb') as file:
        pickle.dump(first_dict, file)
    response = f'gg {message.author.display_name} pour ton {first_dict[message.author.id]}e first ! :D'
    await message.channel.send(response)
    first = False

@client.event
async def on_ready():
    global first_dict
    global member_list
    print(f'{client.user} has connected to Discord!')
    for guild in client.guilds:
        print(f'{guild.id} : {SERVER_TOKEN}')
        member_list = [member for member in guild.members]
    for member in member_list:
        first_dict[member.id] = 0
    if not os.path.exists("scores.pkl"):
        with open('scores.pkl', 'wb') as file:
            pickle.dump(first_dict, file)



client.run(DISCORD_TOKEN)
