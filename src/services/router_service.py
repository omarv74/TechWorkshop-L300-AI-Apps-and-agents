from opentelemetry import trace
from azure.ai.inference.models import SystemMessage, UserMessage

tracer = trace.get_tracer(__name__)

def call_router(router_client, router_prompt, formatted_history, phi_4_deployment):
    """Call the router model and return its reply. Handles content filter errors."""
    with tracer.start_as_current_span("custom_function") as span:
        span.set_attribute("custom_attribute", "value")    
        try:
            router_response = router_client.complete(
                messages=[
                    SystemMessage(content=router_prompt),
                    UserMessage(content=formatted_history),
                ],
                max_tokens=2048,
                temperature=0.8,
                top_p=0.1,
                presence_penalty=0.0,
                frequency_penalty=0.0,
                model=phi_4_deployment
            )
            return router_response.choices[0].message.content
        except Exception as e:
            err_str = str(e)
            if "content_filter" in err_str or "ResponsibleAIPolicyViolation" in err_str:
                return "__CONTENT_FILTER_ERROR__" + err_str
            raise

def select_agent(router_reply: str, env_vars: dict):
    reply = router_reply.lower()
    if "cora" in reply:
        return env_vars.get('cora'), "cora"
    elif "interior_designer" in reply:
        return env_vars.get('interior_designer'), "interior_designer"
    elif "inventory_agent" in reply:
        return env_vars.get('inventory_agent'), "inventory_agent"
    elif "customer_loyalty" in reply:
        return env_vars.get('customer_loyalty'), "customer_loyalty"
    return None, None 