import sys, math, time, shutil, threading
from math import sin, cos

A = B = 0.0
STOP = False

def render_donut():
    global A, B
    w, h = shutil.get_terminal_size()
    w = max(40, w)
    h = max(20, h)
    
    # Enhanced parameters for smaller, cleaner donut [citation:4][citation:8]
    R1, R2, K2 = 0.5, 1.5, 4.5
    K1 = w * K2 * 3 / (8 * (R1 + R2))
    
    # Precompute trig for current rotation
    sinA, cosA = sin(A), cos(A)
    sinB, cosB = sin(B), cos(B)
    
    buf = [' '] * (w * h)
    zbuf = [0.0] * (w * h)
    
    # Finer sampling for perfect rendering (smaller steps = more points) [citation:10]
    theta_step = 0.04
    phi_step = 0.015
    
    theta = 0.0
    while theta < 2 * math.pi:
        ct, st = cos(theta), sin(theta)
        circlex = R2 + R1 * ct
        circley = R1 * st
        
        phi = 0.0
        while phi < 2 * math.pi:
            cp, sp = cos(phi), sin(phi)
            
            # 3D torus coordinates with full rotation matrices [citation:5][citation:8]
            x = circlex * (cosB * cp + sinA * sinB * sp) - circley * cosA * sinB
            y = circlex * (sinB * cp - sinA * cosB * sp) + circley * cosA * cosB
            z = K2 + cosA * circlex * sp + circley * sinA
            
            ooz = 1.0 / z
            xp = int(w/2 + K1 * ooz * x)
            yp = int(h/2 - K1 * ooz * y)
            
            # Luminance (normal) calculation [citation:8]
            L = (cp * ct * sinB - cosA * ct * sp - sinA * st + 
                 cosB * (cosA * st - ct * sinA * sp))
            
            if L > 0 and 0 <= xp < w and 0 <= yp < h:
                idx = xp + yp * w
                if ooz > zbuf[idx]:
                    zbuf[idx] = ooz
                    # Brighter chars for better clarity on smaller donut
                    lum = min(int(L * 12), 11)
                    buf[idx] = " .,-~:;=!*#$@"[lum]
            
            phi += phi_step
        theta += theta_step
    
    sys.stdout.write('\x1b[H' + ''.join(buf))
    sys.stdout.flush()
    A += 0.06
    B += 0.03

def main():
    global STOP
    if not sys.stdout.isatty():
        sys.stderr.write("TTY required\n")
        sys.exit(1)
    
    sys.stdout.write('\x1b[?25l\x1b[2J')
    sys.stdout.flush()
    
    def loop():
        while not STOP:
            render_donut()
            time.sleep(0.02)
    
    t = threading.Thread(target=loop, daemon=True)
    t.start()
    
    try:
        while True:
            time.sleep(0.1)
    except KeyboardInterrupt:
        STOP = True
    finally:
        sys.stdout.write('\x1b[H\x1b[J\x1b[?25h')
        sys.stdout.flush()
        sys.exit(0)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        sys.stderr.write(f"ERROR: {e}\n")
        sys.exit(1)