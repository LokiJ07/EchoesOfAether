"""Draw all original hand-coded pixel sprites and an original short ambient music loop.
No external asset packs, copyrighted sprites or network access required.
"""
from PIL import Image, ImageDraw
from pathlib import Path
import math, wave, random, struct

out=Path(__file__).resolve().parent.parent/'assets';out.mkdir(exist_ok=True)
random.seed(42)

def sprite(name,wh,drawer):
 im=Image.new('RGBA',wh,(0,0,0,0));d=ImageDraw.Draw(im);drawer(d,wh);im.save(out/f'{name}.png')

def hero(d,wh,action):
 # Backing shadow and cloak
 d.ellipse((11,43,31,46), fill='#131726')
 d.polygon([(13,22),(32,20),(37,42),(8,42)], fill='#143945',outline='#0b1725')
 d.polygon([(15,24),(24,26),(12,43)],fill='#217887')
 d.rectangle((14,10,31,27), fill='#f1bb8e',outline='#121c2d',width=2)
 d.rectangle((12,5,33,13),fill='#1b2735')
 d.polygon([(12,8),(17,2),(32,4),(36,11),(26,11),(22,7)],fill='#d0f8e1')
 d.rectangle((27,17,29,19),fill='#182031')
 d.polygon([(12,24),(22,24),(33,28),(30,39),(14,39)],fill='#1c5470',outline='#0a1f30')
 d.rectangle((19,25,25,31),fill='#b1d8b9')
 d.rectangle((8,29,14,33),fill='#f3c59a')
 d.polygon([(28,28),(35,30),(36,34),(30,35)],fill='#f4c493')
 if action=='run':
  d.polygon([(15,39),(22,39),(19,47),(11,47)],fill='#243b56',outline='#0c1624')
  d.polygon([(27,39),(31,39),(37,43),(33,47)],fill='#243b56',outline='#0c1624')
 elif action=='jump':
  d.polygon([(15,39),(22,39),(12,43),(9,40)],fill='#243b56',outline='#0c1624')
  d.polygon([(27,39),(31,39),(39,43),(33,44)],fill='#243b56',outline='#0c1624')
 else:
  d.polygon([(14,39),(22,39),(22,47),(12,47)],fill='#243b56',outline='#0c1624')
  d.polygon([(25,39),(32,39),(34,47),(26,47)],fill='#243b56',outline='#0c1624')
 d.rectangle((15,43,22,46),fill='#a4a2ac')
 d.rectangle((27,43,35,46),fill='#a4a2ac')
 d.polygon([(6,29),(8,25),(11,26),(9,40),(5,42)],fill='#aad7c5')
for state in ['idle','run','jump']:
 sprite('hero_'+state,(48,48),lambda d,wh,state=state:hero(d,wh,state))

def slime(d,s):
 d.ellipse((5,15,43,45), fill='#183f35',outline='#092323',width=3)
 d.ellipse((9,11,42,43),fill='#63b47c',outline='#164637',width=3)
 d.ellipse((14,18,35,32),fill='#8cde9c')
 d.rectangle((16,29,20,34),fill='#111f2e');d.rectangle((30,29,34,34),fill='#111f2e')
 d.rectangle((17,28,19,29),fill='#fcfff1');d.rectangle((30,28,32,29),fill='#fcfff1')
 d.line((21,36,29,36),fill='#2a5547',width=2)
 d.rectangle((7,35,11,38),fill='#a2ecc0')
sprite('slime',(48,48),slime)

def moth(d,s):
 d.ellipse((3,15,25,36),fill='#7ea1c2',outline='#1c3349',width=3)
 d.ellipse((23,15,46,36),fill='#ae77c6',outline='#2b2b4c',width=3)
 d.ellipse((15,10,32,38),fill='#41567d',outline='#132b40',width=3)
 d.ellipse((19,13,28,23),fill='#cadbd5')
 d.point((21,17),fill='#e67bca');d.point((26,17),fill='#e67bca')
 d.line((19,12,13,3),fill='#d7b1c3',width=2);d.line((29,12,36,4),fill='#d7b1c3',width=2)
sprite('moth',(48,48),moth)

def beetle(d,s):
 d.ellipse((5,17,43,44),fill='#33314e',outline='#15182b',width=3)
 d.ellipse((10,12,43,39),fill='#b77953',outline='#452e34',width=3)
 d.polygon([(26,14),(42,18),(37,34),(25,39)],fill='#e2b367')
 d.line((23,13,25,39),fill='#503f50',width=3)
 for x in [7,37]:
  d.line((x,31,x-3,41),fill='#16192d',width=3)
 d.ellipse((11,21,17,26), fill='#d3edc3')
 d.polygon([(13,15),(9,7),(19,12)],fill='#d0c5a0')
sprite('beetle',(48,48),beetle)

def sentinel(d,s):
 d.polygon([(12,7),(35,8),(43,18),(40,44),(9,45),(4,20)],fill='#6c6e84',outline='#1a233a')
 d.polygon([(14,6),(30,5),(41,17),(32,22),(10,21)],fill='#a2a6aa')
 d.rectangle((12,24,38,34),fill='#283448')
 d.rectangle((17,26,22,30),fill='#80d8e0');d.rectangle((30,26,35,30),fill='#80d8e0')
 d.line((23,12,26,22),fill='#b8d7cd',width=2)
 d.rectangle((9,39,16,46),fill='#333e52');d.rectangle((32,39,39,46),fill='#333e52')
sprite('sentinel',(48,48),sentinel)

def wisp(d,s):
 d.polygon([(24,0),(33,11),(43,20),(36,40),(24,48),(12,38),(4,23),(13,12)],fill='#242c61')
 d.polygon([(24,5),(32,16),(37,26),(29,42),(20,36),(11,28),(17,16)],fill='#8a74c8')
 d.ellipse((14,17,34,34),fill='#b5dbea')
 d.ellipse((20,22,27,29),fill='#e4fff2')
 d.point((13,39),fill='#f6b9d6')
sprite('wisp',(48,48),wisp)

def boss(d,s):
 d.polygon([(7,24),(3,5),(18,15),(22,0),(32,14),(45,3),(42,25),(57,18),(49,42),(59,57),(38,52),(32,63),(20,52),(3,59),(9,42),(0,33)],fill='#3b2f58',outline='#191b30')
 d.polygon([(13,21),(31,11),(46,21),(51,43),(34,53),(15,45)],fill='#75618d',outline='#242744')
 d.polygon([(21,20),(32,15),(42,20),(43,34),(32,44),(19,35)],fill='#333854')
 d.ellipse((15,26,28,36),fill='#f2a3b8');d.ellipse((34,26,47,36),fill='#f2a3b8')
 d.rectangle((19,29,25,32),fill='#3d1d43');d.rectangle((37,29,43,32),fill='#3d1d43')
 d.polygon([(25,39),(33,44),(40,39),(36,49),(30,52)],fill='#c0a9e8')
 for x,y in [(11,11),(50,11),(30,7)]:d.ellipse((x-3,y-3,x+3,y+3),fill='#b2e6ee')
sprite('boss',(64,64),boss)

def npc(d,s):
 d.polygon([(10,22),(34,22),(40,48),(7,48)],fill='#79465e',outline='#212239')
 d.rectangle((13,11,33,28),fill='#e4ad8c',outline='#2c2539')
 d.polygon([(8,11),(12,4),(31,3),(38,13),(30,16),(14,12)],fill='#eee0b1')
 d.ellipse((19,18,21,20),fill='#253548');d.ellipse((29,18,31,20),fill='#253548')
 d.rectangle((17,29,27,37),fill='#c5d9c9')
 d.rectangle((13,42,20,49),fill='#34273d');d.rectangle((28,42,36,49),fill='#34273d')
sprite('npc',(48,50),npc)

def tree(d,s,dark=False):
 trunk='#364251' if dark else '#5b4d48'
 leaves=['#223b4b','#264e51','#355963'] if dark else ['#245b50','#357a65','#64a781']
 d.rectangle((26,30,36,95),fill=trunk)
 d.rectangle((29,41,31,88),fill='#9e9b74' if not dark else '#507077')
 for x,y,r in [(28,28,23),(10,45,17),(48,46,16),(39,18,19),(18,22,18)]:
  d.ellipse((x-r,y-r,x+r,y+r),fill=leaves[(x+y)%3],outline='#102b32')
 for x,y in [(14,26),(37,17),(17,43),(51,36),(30,30),(21,10),(43,50)]:
  d.rectangle((x,y,x+3,y+3),fill='#b6f4af' if not dark else '#45757d')
sprite('forest_tree',(64,96),lambda d,s:tree(d,s,False))
sprite('forest_tree_dark',(64,96),lambda d,s:tree(d,s,True))

def house(d,s,shop=False):
 d.rectangle((12,29,83,66),fill='#566378' if shop else '#87765d',outline='#172535',width=3)
 d.polygon([(5,28),(24,8),(71,8),(91,29)],fill='#405e70' if shop else '#a66862',outline='#162535')
 for x in range(26,73,9):d.line((x,11,x-11,28),fill='#c78c74' if not shop else '#7b9ba6',width=2)
 d.rectangle((37,41,58,66),fill='#262c3a')
 d.rectangle((43,44,52,66),fill='#6b6259')
 for x in [19,68]:
  d.rectangle((x,41,x+12,54),fill='#f0cb88',outline='#283c47',width=2)
  d.line((x+6,41,x+6,54),fill='#c07c58',width=2)
 if shop:
  d.rectangle((16,26,76,37),fill='#294f58',outline='#b9cebd',width=1)
  d.ellipse((46,23,50,29),fill='#f5e4a1')
 else:
  d.rectangle((14,62,81,68),fill='#445066')
sprite('house',(96,72),lambda d,s:house(d,s,False))
sprite('shop',(96,72),lambda d,s:house(d,s,True))

def ruin(d,s):
 d.polygon([(11,3),(42,1),(49,13),(43,21),(15,20)],fill='#9d99aa',outline='#37334d')
 d.rectangle((17,21,42,95),fill='#5b5b75',outline='#29283e',width=3)
 for y in [35,67,86]:d.rectangle((12,y,47,y+6),fill='#787d8c',outline='#34334e')
 d.line((32,19,27,41,35,67,31,83),fill='#b8acbf',width=2)
 d.polygon([(6,96),(56,96),(51,86),(13,86)],fill='#62627d',outline='#33314a')
sprite('ruin',(64,96),ruin)

def grass(d,s):
 d.rectangle((0,0,32,32),fill='#2b463d');d.rectangle((0,0,32,8),fill='#3b8064')
 for x in [2,8,17,25,30]:
  d.line((x,7,x+2,2),fill='#8bd8a2',width=2)
 for x,y in [(3,14),(17,16),(26,25),(12,27)]:d.rectangle((x,y,x+4,y+2),fill='#385b4c')
sprite('grass',(32,32),grass)

def rock(d,s):
 d.rectangle((0,0,32,32),fill='#3d4057');d.rectangle((0,0,32,7),fill='#746b8d')
 d.polygon([(4,9),(17,10),(9,22),(3,29)],fill='#4a4f69')
 d.line((21,9,28,21,15,31),fill='#272c46',width=2)
 d.rectangle((21,2,25,6),fill='#9e9bc0')
sprite('rock',(32,32),rock)

def coin(d,s):
 d.ellipse((4,3,25,25),fill='#b07637',outline='#362b33',width=3)
 d.ellipse((7,6,22,22),fill='#f5cf75',outline='#fff0a4',width=1)
 d.rectangle((13,9,16,19),fill='#c28847')
sprite('coin',(30,30),coin)

def seed(d,s):
 d.polygon([(16,1),(28,13),(19,31),(6,20)],fill='#8de3d0',outline='#215f73')
 d.polygon([(16,3),(18,25),(11,18)],fill='#e1fff2')
 d.rectangle((2,7,5,11),fill='#f7ffe3');d.rectangle((26,24,29,27),fill='#f7ffe3')
sprite('seed',(32,32),seed)

def potion(d,s):
 d.rectangle((12,3,22,9),fill='#d7c8a5');d.polygon([(11,8),(23,8),(29,26),(7,26)],fill='#ac535f',outline='#3b304b')
 d.polygon([(11,15),(24,15),(27,26),(8,26)],fill='#ed8f9a')
 d.rectangle((13,4,21,7),fill='#73554c')
sprite('potion',(32,32),potion)

def magic(d,s):
 d.polygon([(16,1),(29,15),(21,38),(8,28),(3,13)],fill='#7e78bb',outline='#28284a')
 d.polygon([(16,5),(22,20),(17,34),(11,20)],fill='#c4f1e4')
sprite('magic',(32,40),magic)

def portal(d,s):
 d.polygon([(17,96),(8,26),(30,3),(48,0),(70,4),(94,26),(88,96)],fill='#3c4261',outline='#1c2839')
 d.polygon([(32,93),(27,32),(45,14),(60,15),(76,32),(74,93)],fill='#23475d')
 d.ellipse((28,20,76,93),fill='#5c7793',outline='#9cc9ba',width=4)
 d.ellipse((39,38,66,83),fill='#b5f0de')
 for x,y in [(14,34),(45,7),(80,39)]:d.ellipse((x-2,y-2,x+2,y+2),fill='#efcaa4')
sprite('portal',(100,100),portal)

# Custom launcher icon.
icon=Image.new('RGBA',(256,256),'#132d3d')
d=ImageDraw.Draw(icon)
d.ellipse((30,30,225,225), fill='#24485a',outline='#82d8ca',width=11)
d.polygon([(128,31),(159,105),(226,121),(164,155),(129,228),(93,156),(34,125),(99,106)], fill='#e1c38b',outline='#f3e7b8')
d.polygon([(128,59),(143,125),(128,192),(112,125)], fill='#84e4d5')
d.ellipse((115,113,141,139),fill='#fcf8dc')
icon.save(out/'icon.png')

# Original ambient track: A minor pentatonic, quiet pulses + arpeggio, no copied melody.
sr=16000;duration=12
notes=[220.0,261.626,329.628,392.0,329.628,261.626,246.942,196.0,220.0,261.626,293.665,329.628,261.626,196.0,164.814,196.0]
samples=[]
for i in range(sr*duration):
 t=i/sr
 melody=notes[int(t*1.333)%len(notes)]
 onset=(t*1.333)%1.0
 env=max(0.0,1.0-onset)**1.8
 pad=0.06*math.sin(math.tau*110*t) + 0.035*math.sin(math.tau*164.814*t)
 arp=0.17*env*(math.sin(math.tau*melody*t)+0.25*math.sin(math.tau*melody*2*t))
 shimmer=0.018*math.sin(math.tau*880*t)*math.sin(math.tau*0.2*t)**2
 val=(pad+arp+shimmer)*0.75
 samples.append(int(max(-1.0,min(1.0,val))*32767))
with wave.open(str(out/'theme.wav'),'wb') as wav:
 wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(sr)
 wav.writeframes(struct.pack('<%dh'%len(samples),*samples))
print('Generated',len(list(out.iterdir())),'original art/audio assets')

# Short original UI/combat sound effects (discrete waveforms; portable WAV import).
effects={'jump':(320,540,.17), 'dash':(690,230,.15), 'attack':(480,160,.14),
         'hit':(210,85,.14),'loot':(600,940,.14),'heal':(392,784,.30),
         'skill':(480,990,.24),'win':(450,900,.68)}
for name,(start,end,seconds) in effects.items():
 frames=[]
 for i in range(int(sr*seconds)):
  t=i/sr
  phase=t/seconds
  f=start+(end-start)*phase
  amplitude=(1-phase)**1.5*(0.6 if name!='win' else 0.4)
  sample=amplitude*(math.sin(math.tau*(start*t+(end-start)*t*t/(2*seconds)))+0.17*math.sin(math.tau*f*2*t))
  frames.append(int(max(-1,min(1,sample))*32767))
 with wave.open(str(out/f'fx_{name}.wav'),'wb') as wav:
  wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(sr)
  wav.writeframes(struct.pack('<%dh'%len(frames),*frames))
