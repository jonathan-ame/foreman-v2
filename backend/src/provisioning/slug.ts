export function workspaceSlugFromCustomer(_customerId: string, workspaceSlug: string): string {
  return workspaceSlug;
}

export function openclawAgentIdFor(workspaceSlug: string, agentName: string): string {
  const safe = agentName.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  return `${workspaceSlug}-${safe}`;
}

export function workspacePathFor(openclawAgentId: string): string {
  return `~/.openclaw/workspace-${openclawAgentId}`;
}
