#!/usr/bin/python
import sys
import math
import time
import operator
import random
import itertools

import pygame
#import lib

class DataType(type):
    """Generic metaclass."""
    def __new__(meta, classname, bases, classDict):
        return type.__new__(meta, classname, bases, classDict)    

def struct(name, **attributes):
    """Construct a class with given attributes (struct-like object).""" 
    def _init(self, **kwargs):
        for key, value in kwargs.iteritems():
            setattr(self, key, value)
    def _repr(self):
        items = ", ".join("%s=%s" % (k, getattr(self, k)) for k in attributes)
        return "<%s %s>" % (name, items)
    return DataType(name, (), 
        dict(__slots__=attributes.keys(), __init__=_init, __repr__=_repr))

def create_screen(size, caption):
    """Create Pygame display with pixel size (width, height) and caption.""" 
    window = pygame.display.set_mode(size)
    pygame.display.set_caption(caption)
    return pygame.display.get_surface()
    
def process_events():
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            return False
    return True

def update_time(itime):    
    now = time.time()
    return (now - itime), now

def take_every(n, iterable):
    """Take an element from iterator every n elements"""
    return itertools.islice(iterable, 0, None, n)

def substract_angles(a, b):
    return min((2 * math.pi) - abs(a - b), abs(a - b))

def collide(obj1, obj2):
    (x1, y1), r1 = obj1.position, obj1.size
    (x2, y2), r2 = obj2.position, obj2.size
    rdist = r1 + r2
    if abs(x1 - x2) > rdist or abs(y1 - y2) > rdist:
        return False
    elif (x1-x2)**2 + (y1-y2)**2 > rdist**2:
        return False
    else:
        return True    

def process_traces(traces, comet, now, dt, new_x, new_y):
    def _pop():
        if len(traces) > 20 or comet.trace_memory_time > 0.025:
            comet.trace_memory_time = 0.0
            return True
        else:
            comet.trace_memory_time += dt
            return False
    def _append():
        if not traces:
            return True
        else:
            return module2(substract_vectors(traces[-1].position, (new_x, new_y))) >= 20.0
    return (traces[1 if _pop() else 0:] + 
        ([Trace(timestamp=now, position=comet.position, size=5)] if _append() else []))

def module2(vector):
    return sum(x**2 for x in vector)
    
def substract_vectors(v1, v2):
    return tuple(x-y for (x, y) in zip(v1, v2))

def add_vectors(*vectors):
    return tuple(x+y for (x, y) in zip(*vectors))

def multiply_vector(k, vector):
    return tuple(k*x for x in vector)

def process_game(game, mouse, now, dt):
    if game.state == "wait_start":
        if mouse.buttons[0]:
            game.state = "playing"
            game.meteors = []
            game.comet = Comet(position=(320, 400), traces=[], size=5, trace_memory_time=0, 
                energy=100, fscore=0.0, score=0)
        return
    x, y = game.comet.position
    traces = game.comet.traces
    mouse_x, mouse_y = mouse.position
    dx, dy = mouse_x - x, mouse_y - y
    angle = math.atan2(dy, dx)
    k = 250.0 * dt
    new_x = x + k * math.cos(angle)
    new_y = y + k * math.sin(angle)
    new_angle = math.atan2(mouse_y - new_y, mouse_x - new_x)
    if substract_angles(angle, new_angle) > math.pi / 2:
        # an abrupt change of angle means that the comet overtook the mouse pointer 
        new_x, new_y = mouse_x, mouse_y
        
    new_traces = process_traces(traces, game.comet, now, dt, new_x, new_y)
    
    for meteor in game.meteors[:]:
        mx, my = meteor.position
        meteor.position = mx + dt*meteor.speed[0], my + dt*meteor.speed[1]
        new_mx, new_my = meteor.position
        if (new_mx - meteor.size > game.screen[0] or
                new_my - meteor.size > game.screen[1]):
            game.meteors.remove(meteor)
        collision = any(collide(meteor, comet) for comet in 
            itertools.chain(take_every(10, game.comet.traces), [game.comet]))
        if collision:            
            game.comet.energy -= 150.0*dt
            if game.comet.energy < 0:
                game.state = "wait_start"

    game.comet.fscore += 100.0 * dt
    game.comet.score = ((int(game.comet.fscore)/50)*50)
    
    if random.random() < 0.05: 
        sw, sh = game.screen
        perimeter = 2 * (sw + sh)
        lst = [((0, 0), (+1, 0)), ((sw, 0), (0, +1)), ((sw, sh), (-1, 0)), ((0, sh), (0, -1))] 
        #div, mod = divmod(random.uniform(0, perimeter), sw)
        #mod = 0
        div, mod = random.uniform(0, sw), random.choice(range(4))
        point, vector = lst[int(mod)]
        position = add_vectors(point, multiply_vector(div, vector))
        new_meteor = Meteor(position=position, size=int(random.uniform(5, 20)), 
            speed=(random.uniform(-150, 250), random.choice([-150, 200])))
        game.meteors.append(new_meteor)
       

    game.comet.position = (new_x, new_y)
    game.comet.traces = new_traces
    return game

Trace = struct("Trace", 
    position=(float, float),
    size=float, 
    timestamp=float,
) 
Comet = struct("Comet", 
    position=(float, float),
    size=float, 
    max_speed=float, 
    traces=[Trace],     
    trace_memory_time=float,
    energy=int,
    fscore=float,
    score=int,
)
Meteor = struct("Meteor", 
    position=(float, float), 
    speed=(float, float), 
    size=int,
)
Mouse = struct("Mouse", position=(int, int), buttons=[bool])

Game = struct("Game", comet=Comet, meteors=[Meteor], screen=(float, float), state=str)
    
def main(args):
    screen = create_screen((640, 480), "Comet")
    comet = Comet(position=(320, 400), traces=[], size=5, trace_memory_time=0, 
        energy=100.0, fscore=0.0, score=0)
    game = Game(comet=comet, meteors=[], screen=screen.get_size(), state="wait_start")
    itime = time.time()
    fps_value, fps_temp, fps_itime = 0, 0, itime
    pygame.font.init()
    fontname = pygame.font.get_default_font()
    font = pygame.font.SysFont(fontname, 24)
    while 1:
        # Draw
        screen.fill((0, 0, 0))
        screen.blit(font.render("fps: %0.0f" % fps_value, False, (0,255,0)), (10, 10))
        for trace in game.comet.traces:
            color = (255, min(255, 500*(itime-trace.timestamp)), 0)
            pygame.draw.circle(screen, color, map(int, trace.position), 5)
        color = (255,128+127*math.sin(itime*5.0),0)
        pygame.draw.circle(screen, color, map(int, game.comet.position), 6)
        for meteor in game.meteors:
            color = (155, 255, 255)
            pygame.draw.circle(screen, color, map(int, meteor.position), meteor.size)
        
        if game.state == "wait_start":
            text = font.render("Press mouse button to start", False, (255,255,255))
            w, h = text.get_size()
            screen.blit(text, ((640-w)/2, (480-h)/2))    
            
        # Energy
        #pygame.draw.rect(screen, (0,0,0), (0, 480-30, 640, 30), 0)
        screen.blit(font.render("Score: %d" % game.comet.score, False, 
            (255,255,255)), (640-120, 480-40))
        pygame.draw.rect(screen, (255,0,0), (640-120, 480-20, game.comet.energy, 10), 0)
        pygame.display.flip()
        
        # Events    
        if not process_events():
            break
        mouse = Mouse(position=pygame.mouse.get_pos(), buttons=pygame.mouse.get_pressed())
        
        # Process game
        dt, itime = update_time(itime)
        process_game(game, mouse, itime, dt)
        
        fps_temp += 1
        if itime > fps_itime + 1.0:
            fps_itime = itime
            fps_value = fps_temp
            fps_temp = 0
        
if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
