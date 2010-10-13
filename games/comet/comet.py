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

def process_state(state, mouse_position, now, dt):
    x, y = state.comet.position
    traces = state.comet.traces
    mouse_x, mouse_y = mouse_position
    dx, dy = mouse_x - x, mouse_y - y
    angle = math.atan2(dy, dx)
    k = 250.0 * dt
    new_x = x + k * math.cos(angle)
    new_y = y + k * math.sin(angle)
    new_angle = math.atan2(mouse_y - new_y, mouse_x - new_x)
    if substract_angles(angle, new_angle) > math.pi / 2:
        # an abrupt change of angle means that the comet overtook the mouse pointer 
        new_x, new_y = mouse_x, mouse_y
        
    new_traces = process_traces(traces, state.comet, now, dt, new_x, new_y)
    
    for meteor in state.meteors[:]:
        mx, my = meteor.position
        meteor.position = mx + dt*meteor.speed[0], my + dt*meteor.speed[1]
        new_mx, new_my = meteor.position
        if (new_mx - meteor.size > state.screen[0] or
                new_my - meteor.size > state.screen[1]):
            state.meteors.remove(meteor)
        for comet in itertools.chain(take_every(10, state.comet.traces), [state.comet]):
            if collide(meteor, comet):
                print "collide", now

    if random.random() < 0.03: 
        sw, sh = state.screen
        perimeter = 2 * (sw + sh)
        lst = [((0, 0), (+1, 0)), ((sw, 0), (0, +1)), ((sw, sh), (-1, 0)), ((0, sh), (0, -1))] 
        #div, mod = divmod(random.uniform(0, perimeter), sw)
        #mod = 0
        div, mod = random.uniform(0, sw), 0
        point, vector = lst[int(mod)]
        position = add_vectors(point, multiply_vector(div, vector))
        new_meteor = Meteor(position=position, size=int(random.uniform(5, 20)), 
            speed=(random.uniform(0, -0), random.choice([250, 300])))
        state.meteors.append(new_meteor)
       

    state.comet.position = (new_x, new_y)
    state.comet.traces = new_traces
    return state

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
    score=int,
)
Meteor = struct("Meteor", 
    position=(float, float), 
    speed=(float, float), 
    size=int,
)
State = struct("State", comet=Comet, meteors=[Meteor], screen=(float, float))
Game = struct("Game", state=State, config=dict)
    
def main(args):
    screen = create_screen((640, 480), "Comet")
    meteor = Meteor(position=(100, 100), speed=(50, 70), size=30)
    meteor2 = Meteor(position=(500, 200), speed=(-10, 10), size=25)
    comet = Comet(position=(320, 400), traces=[], size=5, trace_memory_time=0)
    state = State(comet=comet, meteors=[], screen=screen.get_size())
    itime = time.time()
    fps_value, fps_temp, fps_itime = None, 0, itime
    while 1:
        # Draw
        screen.fill((0, 0, 0))
        for trace in state.comet.traces:
            color = (255, min(255, 500*(itime-trace.timestamp)), 0)
            pygame.draw.circle(screen, color, map(int, trace.position), 5)
        color = (255,128+127*math.sin(itime*5.0),0)
        pygame.draw.circle(screen, color, map(int, state.comet.position), 6)
        for meteor in state.meteors:
            color = (155, 255, 255)
            pygame.draw.circle(screen, color, map(int, meteor.position), meteor.size)
        pygame.display.flip()
        
        # Events    
        if not process_events():
            break
        mouse_position = pygame.mouse.get_pos()
        
        # Process state
        dt, itime = update_time(itime)
        state = process_state(state, mouse_position, itime, dt)
        fps_temp += 1
        if itime > fps_itime + 1.0:
            fps_itime = itime
            fps_value = fps_temp
            fps_temp = 0
            print fps_value
        
if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
