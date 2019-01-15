"""
This example:

1. Connects to current controller.
2. List models

"""
import logging

from juju.controller import Controller
from juju import loop
from juju.model import Model


async def main():
    controller = Controller()
    # connect to current controller with current user, per Juju CLI
    await controller.connect()
    modellist = await controller.list_models()
    print(modellist)
    for modelName in modellist:
        model = Model()
        try:
            # connect to the current model with the current user, per the Juju CLI
            await model.connect(modelName)
            print('\n********* Model: ', modelName, ' ********')
            print('\nThere are {} applications'.format(len(model.applications)))
            for appl in model.applications.values():
                #print(dir(appl))
                print("Name: ",appl.data['name']," charm-url: ", appl.data['charm-url'], " exposed: ", appl.data['exposed'])
                print(repr(appl),appl.status)
                #appconfig = await appl.get_config()
                #print('\nApp Config: ')
                #for cfg in appconfig:
                #    print('    ',cfg)
                for unit in appl.units:
                    print("{}: {}".format(
                    unit.name, await unit.is_leader_from_status()))

            print('\nThere are {} machines'.format(len(model.machines)))
            for mach in model.machines:
                print(mach)
        finally:
            if model.is_connected():
                print('Disconnecting from model')
                await model.disconnect()

    #   print(model['name'],model['owner-tag'])
    await controller.disconnect()


if __name__ == '__main__':
    #logging.basicConfig(level=logging.DEBUG)
    #ws_logger = logging.getLogger('websockets.protocol')
    #ws_logger.setLevel(logging.INFO)
    loop.run(main())
