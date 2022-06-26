import { AzureFunction, Context, HttpRequest } from "@azure/functions";

const httpTrigger: AzureFunction = async function (
  context: Context,
  req: HttpRequest
): Promise<void> {
  context.log("** HTTP **");
  const name = req.query.name || (req.body && req.body.name);
  const responseMessage = name ? "Hello there, " + name : "Hello";

  context.bindings.outputQueueItem = "q:" + name;

  context.res = {
    // status: 200, /* Defaults to 200 */
    body: responseMessage,
  };
};

export default httpTrigger;
