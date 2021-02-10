import numpy as np
import cv2
import time
import socket
import threading
# import select


def make_frame(imarray, i):
  imarray[:] = 0
  cv2.putText(imarray, f'Frame {i}', (100, 100),
              cv2.FONT_HERSHEY_SIMPLEX, 3, (255, 255, 255), 3, 2)


def gen_fake_frames(port):
  frame_rate = 15
  addr_list = []

  i = 0
  im_array = np.zeros((1280, 1024), dtype=np.uint8)

  host = '127.0.0.1'

  sock = initTCP(host, port)

  blockForConnections(sock, addr_list)

  while True:
    try:
      conn, addr = sock.accept()
      addr_list.append((conn, addr))
      print(f'New connected client: {addr}')
    except BlockingIOError:
      pass

    if len(addr_list) == 0:
      blockForConnections(sock, addr_list)

    last_time = time.time()

    make_frame(im_array, i)

    bytes_out = im_array.tobytes()  # only saving this as separate variable for timing
    if i % frame_rate == frame_rate-1:
      print(f'Wrote frame {i+1} ({i // frame_rate + 1} seconds elapsed)')

    for j, (conn, addr) in reversed(list(enumerate(addr_list))):
      # NOTE: read reversed list so that we can drop clients if necessary
      try:
        conn.send(bytes_out)  # TODO: not guaranteed to send all data??
      except (ConnectionAbortedError, ConnectionResetError):  # disconnection
        print(f'Client {addr} disconnected.')
        del addr_list[j]
        if len(addr_list) == 0:
          print('No more connected clients. Pausing.')
          continue
      except BlockingIOError:
        pass

    time.sleep(max(1/frame_rate - (time.time() - last_time), 0))

    i += 1


def initTCP(host, port):
  sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM) #127.0.0.1
  sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
  sock.bind((host, port))
  sock.listen()
  return sock


def blockForConnections(sock, addr_list):
  sock.setblocking(True)
  host, port = sock.getsockname()
  print(f'Listening for clients on {host}:{port}')
  conn, addr = sock.accept()
  addr_list.append((conn, addr))
  sock.setblocking(False)
  print(f'New connected client: {addr}')


if __name__ == '__main__':
  # threading.Thread(target=gen_fake_frames, args=(5003,)).start()
  # threading.Thread(target=gen_fake_frames, args=(5004,)).start()
  # threading.Thread(target=gen_fake_frames, args=(5005,)).start()
  gen_fake_frames(5002)
