import { AzureFunction, Context } from "@azure/functions";

const queueTrigger: AzureFunction = async function (
  context: Context,
  myQueue: string
): Promise<void> {
  context.log("** QUEUE **", myQueue);
};

export default queueTrigger;
