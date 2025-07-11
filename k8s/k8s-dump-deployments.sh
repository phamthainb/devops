echo "📁 Creating export directory: $EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

# Get all namespaces
echo "🔍 Fetching all namespaces with deployments..."
namespaces=$(kubectl get ns -o jsonpath="{.items[*].metadata.name}")

for ns in $namespaces; do
    echo "➡️  Processing namespace: $ns"
    
    # Get all deployments in this namespace
    deployments=$(kubectl get deployments -n "$ns" --no-headers --output=custom-columns=":metadata.name")

    for deploy in $deployments; do
        echo "   📦 Exporting deployment: $deploy"
        
        # Create directory for namespace
        mkdir -p "$EXPORT_DIR/$ns"
        
        # Export the deployment YAML
        kubectl get deployment "$deploy" -n "$ns" -o yaml > "$EXPORT_DIR/$ns/$deploy.yaml"

        echo "   ✅ Saved to: $EXPORT_DIR/$ns/$deploy.yaml"
    done
done

echo "🏁 Done exporting all deployments!"
